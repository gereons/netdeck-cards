//
//  ImageCache.m
//  Net Deck
//
//  Created by Gereon Steffens on 16.01.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "ImageCache.h"
#import <EXTScope.h>
#import <AFNetworking.h>

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
    
    // repair busted settings
    if (lastCheck > today)
    {
        lastCheck = today - 1;
    }
    
    if (floor(lastCheck) < floor(today))
    {
        unavailableImages = [NSMutableSet set];
        [settings setDouble:today forKey:UNAVAIL_IMG_DATE];
        [settings setObject:@[] forKey:UNAVAILABLE_IMG];
    }
    
    memCache = [[NSCache alloc] init];
    memCache.name = @"netdeck";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [ImageCache initializeMemCache];
    });
}

+(ImageCache*) sharedInstance
{
    if (instance == nil)
    {
        instance = [ImageCache new];
    }
    return instance;
}

-(void) clearLastModifiedInfo
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@{} forKey:LAST_MOD_CACHE];
    [settings setObject:@{} forKey:NEXT_CHECK];
    [settings synchronize];
    
    [memCache removeAllObjects];
}

-(void) clearCache
{
    [self clearLastModifiedInfo];
    
    unavailableImages = [NSMutableSet set];
    [[NSUserDefaults standardUserDefaults] setObject:unavailableImages.allObjects forKey:UNAVAILABLE_IMG];
    
    [ImageCache removeCacheDirectory];
}

-(void) getImageFor:(Card *)card completion:(CompletionBlock)completionBlock
{
    NSString* key = card.code;
    
    UIImage* img = [memCache objectForKey:key];
    if (img)
    {
        completionBlock(card, img, NO);
        return;
    }
    
    // if we know we don't (or can't) have an image, return a placeholder immediately
    if (card.imageSrc == nil || [unavailableImages containsObject:key])
    {
        completionBlock(card, [ImageCache placeholderFor:card.role], YES);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // get image from our on-disk cache
        UIImage* img = [ImageCache getDecodedImageFor:key];
        
        if (img)
        {
            if (APP_ONLINE)
            {
                [self checkForImageUpdate:card withKey:key];
            }
            
            [memCache setObject:img forKey:key];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(card, img, NO);
            });
        }
        else
        {
            // image is not in on-disk cache
            if (APP_ONLINE)
            {
                [self downloadImageFor:card withKey:key completion:^(Card *card, UIImage *image, BOOL placeholder) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(card, image, placeholder);
                    });
                }];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(card, [ImageCache placeholderFor:card.role], YES);
                });
            }
        }
    });
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
    
    NSString* url = card.imageSrc;
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
             
             if ([unavailableImages containsObject:key])
             {
                 [unavailableImages removeObject:key];
                 [[NSUserDefaults standardUserDefaults] setObject:unavailableImages.allObjects forKey:UNAVAILABLE_IMG];
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
    // NSLog(@"get img for %@", key);
    
    UIImage* img = [ImageCache getImageFor:card.code];
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
    NSString* url = card.imageSrc;
    if (!APP_ONLINE || url == nil)
    {
        completionBlock(NO);
        return;
    }
    
    NSString* key = card.code;
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSDictionary* dict = [settings objectForKey:LAST_MOD_CACHE];
    NSString* lastModDate = [dict objectForKey:key];
    
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
        if (responseObject)
        {
            [self storeInCache:responseObject lastModified:lastModified forKey:key];
        }
        completionBlock(responseObject != nil);
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSInteger status = operation.response.statusCode;
        NLOG(@"up: GOT %@ If-Modified-Since %@: status %ld", url, lastModDate ?: @"n/a", (long)status);
        completionBlock(status == 304);
    }];
    [operation start];
}

-(void) checkForImageUpdate:(Card*)card withKey:(NSString*)key
{
    NSString* url = card.imageSrc;
    if (url == nil)
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
    NSAssert(image != nil, @"no image");
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
    
    BOOL ok = [ImageCache saveImage:image forKey:key];
    if (!ok)
    {
        NSMutableDictionary* dict = [[settings objectForKey:LAST_MOD_CACHE] mutableCopy];
        [dict removeObjectForKey:key];
        [settings setObject:dict forKey:LAST_MOD_CACHE];
    }
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

+(UIImage*) placeholderFor:(NRRole)role
{
    return role == NRRoleRunner ? runnerPlaceholder : corpPlaceholder;
}

#pragma mark simple filesystem cache

+(void) initializeMemCache
{
    // NSLog(@"start initMemCache");
    NSString* dir = [ImageCache directoryForImages];
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
    
    for (NSString* file in files)
    {
        NSString* imgFile = [dir stringByAppendingPathComponent:file];
        NSData* imgData = [NSData dataWithContentsOfFile:imgFile];
        if (imgData)
        {
            UIImage* img = [ImageCache decodedImage:[UIImage imageWithData:imgData]];
            if (img)
            {
                [memCache setObject:img forKey:file];
            }
        }
    }
    // NSLog(@"end initMemCache");
}

-(BOOL) imageAvailableFor:(Card*)card
{
    NSString* key = card.code;
    
    UIImage* img = [memCache objectForKey:key];
    if (img)
    {
        return YES;
    }
    
    // if we know we don't (or can't) have an image, return a placeholder immediately
    if (card.imageSrc == nil || [unavailableImages containsObject:key])
    {
        return NO;
    }
    
    NSString* dir = [ImageCache directoryForImages];
    NSString* file = [dir stringByAppendingPathComponent:key];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:file];
}

+(NSString*) directoryForImages
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    NSString* directory = [documentsDirectory stringByAppendingPathComponent:@"images"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return directory;
}

+(void) removeCacheDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
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
    
    img = [ImageCache getDecodedImageFor:key];
        
    if (img)
    {
        [memCache setObject:img forKey:key];
    }
    return img;
}

+(UIImage*) getDecodedImageFor:(NSString*) key
{
    NSString* dir = [ImageCache directoryForImages];
    NSString* file = [dir stringByAppendingPathComponent:key];
    
    NSData* imgData = [NSData dataWithContentsOfFile:file];
    UIImage* img = nil;
    if (imgData)
    {
        img = [ImageCache decodedImage:[UIImage imageWithData:imgData]];
    }
    
    if (img == nil || img.size.width < 200)
    {
        // image is broken - remove it
        img = nil;
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
        
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary* dict = [[settings objectForKey:LAST_MOD_CACHE] mutableCopy];
        [dict removeObjectForKey:key];
        [settings setObject:dict forKey:LAST_MOD_CACHE];
    }
    
    return img;
}

+(BOOL) saveImage:(UIImage*)img forKey:(NSString*)key
{
    NLOG(@"save img for %@", key);
    NSString* dir = [ImageCache directoryForImages];
    NSString* file = [dir stringByAppendingPathComponent:key];
    
    if (img && img.size.width > 300)
    {
        // rescale image to 300x418 and save the scaled-down version
        UIImage* newImg = [ImageCache scaleImage:img toSize:CGSizeMake(IMAGE_WIDTH, IMAGE_HEIGHT)];
        if (newImg)
        {
            img = newImg;
        }
    }

    [memCache setObject:img forKey:key];
    NSData* data = UIImagePNGRepresentation(img);
    
    if (data != nil)
    {
        [data writeToFile:file atomically:YES];
        return YES;
    }
    return NO;
}

#pragma mark utility methods

+(UIImage*) scaleImage:(UIImage*)srcImage toSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    
    [srcImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(UIImage*) croppedImage:(UIImage*)img forCard:(Card *)card
{
    NSAssert(img != nil, @"nil image to crop");
    float scale = 1.0;
    if (img.size.width * img.scale > 300)
    {
        scale = 1.436;
    }
    NSString* key = [NSString stringWithFormat:@"%@:crop", card.code ];
    
    UIImage* cropped = [memCache objectForKey:key];
    if (!cropped)
    {
        CGRect rect = CGRectMake((int)(10*scale), (int)(card.cropY*scale), (int)(280*scale), (int)(209*scale));
        CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], rect);
        cropped = [UIImage imageWithCGImage:imageRef];
        NSAssert(cropped != nil, @"nil cropped image");
        CGImageRelease(imageRef);
        if (cropped)
        {
            [memCache setObject:cropped forKey:key];
        }
    }
    return cropped;
}

// see https://stackoverflow.com/questions/12096338/images-from-documents-asynchronous
+(UIImage*) decodedImage:(UIImage*)img
{
    CGImageRef imageRef = img.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 8,
                                                 // Just always return width * 4 will be enough
                                                 CGImageGetWidth(imageRef) * 4,
                                                 // System only supports RGB, set explicitly
                                                 colorSpace,
                                                 // Makes system don't need to do extra conversion when displayed.
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    if (!context)
    {
        return nil;
    }
    
    CGRect rect = CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [[UIImage alloc] initWithCGImage:decompressedImageRef scale:img.scale orientation:img.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

@end
