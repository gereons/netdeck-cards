//
//  ImageCache.m
//  NRDB
//
//  Created by Gereon Steffens on 16.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "ImageCache.h"
#import <EXTScope.h>

#import "Card.h"
#import "SettingsKeys.h"

#define SEC_PER_DAY         (24 * 60 * 60)
#define SUCCESS_INTERVAL    (30*SEC_PER_DAY)
#define ERROR_INTERVAL      (1*SEC_PER_DAY)

#define NETWORK_LOG         (DEBUG && 0)

#if NETWORK_LOG
#define NLOG(fmt, ...)      do { NSLog(fmt, ##__VA_ARGS__); } while(0)
#else
#define NLOG(...)           do {} while(0)
#endif

@implementation ImageCache

static ImageCache* instance;
static UIImage* runnerPlaceholder;
static UIImage* corpPlaceholder;

static UIImage* cardIcon;
static UIImage* creditIcon;
static UIImage* difficultyIcon;
static UIImage* influenceIcon;
static UIImage* linkIcon;
static UIImage* muIcon;
static UIImage* apIcon;
static UIImage* trashIcon;
static UIImage* strengthIcon;
static UIImage* altArtIconOn;
static UIImage* altArtIconOff;
static UIImage* hexTile;

static NSMutableSet* unavailableImages; // set of image keys

static NSCache* memCache;

+(void) initialize
{
    runnerPlaceholder = [UIImage imageNamed:@"RunnerPlaceholder"];
    corpPlaceholder = [UIImage imageNamed:@"CorpPlaceholder"];
    
    trashIcon = [UIImage imageNamed:@"cardstats_trash"];
    strengthIcon = [UIImage imageNamed:@"cardstats_strength"];
    creditIcon = [UIImage imageNamed:@"cardstats_credit"];
    muIcon = [UIImage imageNamed:@"cardstats_mem"];
    apIcon = [UIImage imageNamed:@"cardstats_points"];
    linkIcon = [UIImage imageNamed:@"cardstats_link"];
    cardIcon = [UIImage imageNamed:@"cardstats_decksize"];
    difficultyIcon = [UIImage imageNamed:@"cardstats_difficulty"];
    influenceIcon = [UIImage imageNamed:@"cardstats_influence"];
    
    altArtIconOn = [UIImage imageNamed:@"altarttoggle_on"];
    altArtIconOff = [UIImage imageNamed:@"altarttoggle_off"];
    
    hexTile = [UIImage imageNamed:@"hex_background"];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if ([settings objectForKey:LAST_MOD_CACHE] == nil)
    {
        [settings setObject:@{} forKey:LAST_MOD_CACHE];
    }
    if ([settings objectForKey:NEXT_CHECK] == nil)
    {
        [settings setObject:@{} forKey:NEXT_CHECK];
    }

    NSArray* imgs = [settings objectForKey:UNAVAILABLE_IMG];
    if (imgs == nil)
    {
        unavailableImages = [NSMutableSet set];
    }
    else
    {
        unavailableImages = [NSMutableSet setWithArray:imgs];
    }
    NSTimeInterval today = [NSDate date].timeIntervalSinceReferenceDate / (48*60*60);
    NSTimeInterval lastCheck = [settings doubleForKey:UNAVAIL_IMG_DATE];
    if (floor(lastCheck) < floor(today))
    {
        unavailableImages = [NSMutableSet set];
        [settings setDouble:today forKey:UNAVAIL_IMG_DATE];
        [settings setObject:@[] forKey:UNAVAILABLE_IMG];
        [settings synchronize];
    }
    
    memCache = [[NSCache alloc] init];
    memCache.name = @"netdeck";
}

+(ImageCache*) sharedInstance
{
    if (instance == nil)
    {
        instance = [ImageCache new];
    }
    return instance;
}

-(void) clearCache
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@{} forKey:LAST_MOD_CACHE];
    [settings setObject:@{} forKey:NEXT_CHECK];
    [settings synchronize];
    
    [memCache removeAllObjects];
    
    [ImageCache removeCacheDirectory];
}

-(void) getImageFor:(Card *)card completion:(CompletionBlock)completionBlock
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* key = [NSString stringWithFormat:@"%@:%@", card.code, language];
    
    // NSLog(@"get img for %@", key);
    UIImage* img = [ImageCache getImageFor:key];
    if (img)
    {
        // NSLog(@"cached, check for update");
        if (APP_ONLINE)
        {
            [self checkForImageUpdate:card withKey:key];
        }
        
        if (completionBlock)
        {
            completionBlock(card, img, NO);
        }
        
        return;
    }
    
    // return a placeholder if we're offline or already know that the img is unavailable
    if (!APP_ONLINE || [unavailableImages containsObject:key])
    {
        completionBlock(card, [ImageCache placeholderFor:card.role], YES);
    }
    else
    {
        [self downloadImageFor:card withKey:key completion:completionBlock];
    }
}

-(void) downloadImageFor:(Card *)card withKey:(NSString*)key completion:(CompletionBlock)completionBlock
{
    NSString* src = card.imageSrc;
    if (src == nil)
    {
        if (completionBlock)
        {
            UIImage* img = [ImageCache placeholderFor:card.role];
            completionBlock(card, img, YES);
        }
        return;
    }
    
    NSString* url = [NSString stringWithFormat:@"http://netrunnerdb.com%@", src];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    @weakify(self);
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             @strongify(self);
             // download successful
             
             NLOG(@"dl: GET %@: status 200", url);
             // invoke callback
             if (completionBlock)
             {
                 completionBlock(card, responseObject, NO);
             }
             
             NSString* lastModified = operation.response.allHeaderFields[@"Last-Modified"];
             if (lastModified.length)
             {
                 [self storeInCache:responseObject lastModified:lastModified forKey:key];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // download failed
#if NETWORK_LOG
             NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
             NLOG(@"dl: GET %@ for %@: error %ld", url, card.name, (long)response.statusCode);
#endif
             // invoke callback
             if (completionBlock)
             {
                 UIImage* img = [ImageCache placeholderFor:card.role];
                 completionBlock(card, img, YES);
             }
             [unavailableImages addObject:key];
             [[NSUserDefaults standardUserDefaults] setObject:unavailableImages.allObjects forKey:UNAVAILABLE_IMG];
         }];
}

-(void) updateMissingImageFor:(Card *)card completion:(UpdateCompletionBlock)completionBlock
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* key = [NSString stringWithFormat:@"%@:%@", card.code, language];
    // NSLog(@"get img for %@", key);
    
    UIImage* img = [ImageCache getImageFor:key];
    if (img == nil)
    {
        [self updateImageFor:card completion:completionBlock];
    }
    else
    {
        completionBlock(YES);
    }
}

-(void) updateImageFor:(Card *)card completion:(UpdateCompletionBlock)completionBlock
{
    NSString* src = card.imageSrc;
    if (!APP_ONLINE || src == nil)
    {
        completionBlock(NO);
        return;
    }
    
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* key = [NSString stringWithFormat:@"%@:%@", card.code, language];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSDictionary* dict = [settings objectForKey:LAST_MOD_CACHE];
    NSString* lastModDate = [dict objectForKey:key];
    
    NSString* url = [NSString stringWithFormat:@"http://netrunnerdb.com%@", src];
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    if (lastModDate)
    {
        [request setValue:lastModDate forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        NSString* lastModified = operation.response.allHeaderFields[@"Last-Modified"];
        NLOG(@"up: GOT %@ If-Modified-Since %@: status 200", url, lastModDate ?: @"n/a");
        [self storeInCache:responseObject lastModified:lastModified forKey:key];
        completionBlock(YES);
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // @strongify(self);
        NSInteger status = operation.response.statusCode;
        NLOG(@"up: GOT %@ If-Modified-Since %@: status %ld", url, lastModDate ?: @"n/a", (long)status);
        completionBlock(status == 304);
    }];
    [operation start];
}

-(void) checkForImageUpdate:(Card*)card withKey:(NSString*)key
{
    NSString* src = card.imageSrc;
    if (src == nil)
    {
        return;
    }
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    NSDictionary* dict = [settings objectForKey:NEXT_CHECK];
    NSDate* nextCheck = [dict objectForKey:key];
    if (nextCheck)
    {
        NSDate* now = [NSDate date];
        if ([now timeIntervalSinceDate:nextCheck] < 0)
        {
            // no need to check
            return;
        }
    }
    
    NLOG(@"check for %@: %@", key, nextCheck);
    dict = [settings objectForKey:LAST_MOD_CACHE];
    NSString* lastModDate = [dict objectForKey:key];
    
    NSString* url = [NSString stringWithFormat:@"http://netrunnerdb.com%@", src];
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    if (lastModDate)
    {
        [request setValue:lastModDate forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    NLOG(@"GET %@ If-Modified-Since %@", url, lastModDate ?: @"n/a");
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        
        // got 200 - new image. store in caches
        NLOG(@"GOT %@ If-Modified-Since %@: status 200", url, lastModDate);
        NSString* lastModified = operation.response.allHeaderFields[@"Last-Modified"];
        
        [self storeInCache:responseObject lastModified:lastModified forKey:key];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(self);
        
        NLOG(@"GOT %@ If-Modified-Since %@: status %ld", url, lastModDate, (long)operation.response.statusCode);
        if (operation.response.statusCode == 304)
        {
            // not modified - update check date
            [self setNextCheck:key withTimeIntervalFromNow:SUCCESS_INTERVAL];
        }
        else
        {
            NLOG(@"%@", operation);
            [self setNextCheck:key withTimeIntervalFromNow:ERROR_INTERVAL];
        }
    }];
    
    [operation start];
}

-(void) storeInCache:(UIImage*)image lastModified:(NSString*)lastModified forKey:(NSString*)key
{
    // NSLog(@"store img for %@", key);
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSTimeInterval interval = SUCCESS_INTERVAL;
    if (lastModified)
    {
        NSMutableDictionary* dict = [[settings objectForKey:LAST_MOD_CACHE] mutableCopy];
        [dict setObject:lastModified forKey:key];
        [settings setObject:dict forKey:LAST_MOD_CACHE];
    }
    else
    {
        interval = ERROR_INTERVAL;
    }
    
    [self setNextCheck:key withTimeIntervalFromNow:interval];
    
    [ImageCache saveImage:image forKey:key];
}

-(void) setNextCheck:(NSString*)key withTimeIntervalFromNow:(NSTimeInterval)interval
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* dict = [[settings objectForKey:NEXT_CHECK] mutableCopy];

    NSTimeInterval nextCheck = [NSDate timeIntervalSinceReferenceDate];
    nextCheck += interval;
    NSDate* next = [NSDate dateWithTimeIntervalSinceReferenceDate:nextCheck];
    [dict setObject:next forKey:key];
    
    NLOG(@"set next check for %@ to %@", key, next);
    [settings setObject:dict forKey:NEXT_CHECK];
}

#pragma mark icon/image access

+(UIImage*) trashIcon { return trashIcon; }
+(UIImage*) strengthIcon { return strengthIcon; }
+(UIImage*) creditIcon { return creditIcon; }
+(UIImage*) muIcon { return muIcon; }
+(UIImage*) apIcon { return apIcon; }
+(UIImage*) linkIcon { return linkIcon; }
+(UIImage*) cardIcon { return cardIcon; }
+(UIImage*) difficultyIcon { return difficultyIcon; }
+(UIImage*) influenceIcon { return influenceIcon; }
+(UIImage*) hexTile { return hexTile; }
+(UIImage*) altArtIcon:(BOOL)on { return on ? altArtIconOn : altArtIconOff; }
+(UIImage*) placeholderFor:(NRRole)role
{
    return role == NRRoleRunner ? runnerPlaceholder : corpPlaceholder;
}

#pragma mark simple filesystem cache

+(NSString*) directoryForImages
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    NSString* directory = [documentsDirectory stringByAppendingPathComponent:@"images"];
    directory = [directory stringByAppendingPathComponent:language];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return directory;
}

+(void) removeCacheDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    NSString* directory = [documentsDirectory stringByAppendingPathComponent:@"images"];
    
    [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
}

+(UIImage*) getImageFor:(NSString*)key
{
    UIImage* img = [memCache objectForKey:key];
    
    if (img)
    {
        return img;
    }
    
    NSString* dir = [ImageCache directoryForImages];
    NSString* file = [dir stringByAppendingPathComponent:key];
    
    NSData* imgData = [NSData dataWithContentsOfFile:file];
    if (imgData)
    {
        img = [UIImage imageWithData:imgData];
    }
    
    if (img && img.size.width < 200)
    {
        // image is broken - remove it
        img = nil;
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    }
        
    if (img)
    {
        [memCache setObject:img forKey:key];
    }
    return img;
}

+(void) saveImage:(UIImage*)img forKey:(NSString*)code
{
    NLOG(@"save img for %@", code);
    NSString* dir = [ImageCache directoryForImages];
    NSString* file = [dir stringByAppendingPathComponent:code];
    
    NSData* data = UIImagePNGRepresentation(img);
    
    [data writeToFile:file atomically:YES];
    [self dontBackupFile:file];
}

+(void)dontBackupFile:(NSString*)filename
{
    NSURL* url = [NSURL fileURLWithPath:filename];
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"file doesn't exist");
    
    NSError *error = nil;
    [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
}

#pragma mark utility methods

+(UIImage*) croppedImage:(UIImage*)img forCard:(Card *)card
{
    float scale = 1.0;
    if (img.size.width * img.scale > 300)
    {
        scale = 1.436;
    }
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* key = [NSString stringWithFormat:@"%@:%@:crop", card.code, language];
    
    UIImage* cropped = [memCache objectForKey:key];
    if (!cropped)
    {
        CGRect rect = CGRectMake((int)(10*scale), (int)(card.cropY*scale), (int)(280*scale), (int)(209*scale));
        CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], rect);
        cropped = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        [memCache setObject:cropped forKey:key];
    }
    return cropped;
}

@end

