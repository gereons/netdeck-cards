//
//  ImageCache.m
//  NRDB
//
//  Created by Gereon Steffens on 16.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "ImageCache.h"
#import <TMCache.h>
#import <AFNetworking.h>
#import "Card.h"
#import "SettingsKeys.h"

#define LAST_MOD_CACHE  @"lastModified"
#define NEXT_CHECK      @"nextCheck"

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

#define PLACEHOLDER(card)   (card.role == NRRoleRunner ? runnerPlaceholder : corpPlaceholder)

#define ROUND /* "_round" */

+(void) initialize
{
    runnerPlaceholder = [UIImage imageNamed:@"RunnerPlaceholder"];
    corpPlaceholder = [UIImage imageNamed:@"CorpPlaceholder"];
    
    trashIcon = [UIImage imageNamed:@"trashicon" ROUND];
    strengthIcon = [UIImage imageNamed:@"strengthicon" ROUND];
    creditIcon = [UIImage imageNamed:@"crediticon" ROUND];
    muIcon = [UIImage imageNamed:@"memicon" ROUND];
    apIcon = [UIImage imageNamed:@"pointsicon" ROUND];
    linkIcon = [UIImage imageNamed:@"linkicon" ROUND];
    cardIcon = [UIImage imageNamed:@"cardicon" ROUND];
    difficultyIcon = [UIImage imageNamed:@"difficultyicon" ROUND];
    influenceIcon = [UIImage imageNamed:@"influenceicon" ROUND];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if ([settings objectForKey:LAST_MOD_CACHE] == nil)
    {
        [settings setObject:@{} forKey:LAST_MOD_CACHE];
    }
    if ([settings objectForKey:NEXT_CHECK] == nil)
    {
        [settings setObject:@{} forKey:NEXT_CHECK];
    }
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
    
    [[TMCache sharedCache] removeAllObjects];
}

-(void) getImageFor:(Card *)card success:(CompletionBlock)successBlock failure:(CompletionBlock)failureBlock
{
    [self getImageFor:card success:successBlock failure:failureBlock forced:NO];
}

-(void) getImageFor:(Card *)card success:(CompletionBlock)successBlock failure:(CompletionBlock)failureBlock forced:(BOOL)forced
{
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSString* key = [NSString stringWithFormat:@"%@:%@", card.code, language];
    // NSLog(@"get img for %@", key);
    UIImage* img = [[TMCache sharedCache] objectForKey:key];
    if (img)
    {
        // NSLog(@"cached, check for update");
        [self checkForImageUpdate:card withKey:key forced:forced];
        
        if (successBlock)
        {
            successBlock(card, img);
        }
        
        return;
    }
    
    if (![AFNetworkReachabilityManager sharedManager].reachable)
    {
        successBlock(card, PLACEHOLDER(card));
        return;
    }
    else
    {
        [self downloadImageFor:card withKey:key success:successBlock failure:failureBlock];
    }
}

-(void) downloadImageFor:(Card *)card withKey:(NSString*)key success:(CompletionBlock)successBlock failure:(CompletionBlock)failureBlock
{
    NSString* url = [NSString stringWithFormat:@"http://netrunnerdb.com%@", card.imageSrc];
    
    NLOG(@"GET %@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // download successful
             
             NLOG(@"GET %@: status 200", url);
             // invoke callback
             if (successBlock)
             {
                 successBlock(card, responseObject);
             }
             
             NSString* lastModified = operation.response.allHeaderFields[@"Last-Modified"];
             [self storeInCache:responseObject lastModified:lastModified forKey:key];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // download failed
#if NETWORK_LOG
             NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
             NLOG(@"GET %@: error %d", url, response.statusCode);
#endif
             
             // invoke callback
             if (failureBlock)
             {
                 failureBlock(card, PLACEHOLDER(card));
                 
                 [self storeInCache:PLACEHOLDER(card) lastModified:nil forKey:key];
             }
         }];
}

-(void) checkForImageUpdate:(Card*)card withKey:(NSString*)key forced:(BOOL)forced
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    NSDictionary* dict = [settings objectForKey:NEXT_CHECK];
    if (!forced)
    {
        NSDate* nextCheck = [dict objectForKey:key];
        if (nextCheck)
        {
            NSDate* now = [NSDate date];
            if ([now timeIntervalSinceDate:nextCheck] < 0)
            {
                // NSLog(@"no check needed");
                // no need to check
                return;
            }
        }
    }
    
    dict = [[settings objectForKey:LAST_MOD_CACHE] mutableCopy];
    NSString* lastModDate = [dict objectForKey:key];
    
    NSString* url = [NSString stringWithFormat:@"http://netrunnerdb.com%@", card.imageSrc];
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    if (lastModDate)
    {
        [request setValue:lastModDate forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    NLOG(@"GET %@ If-Modified-Since %@", url, lastModDate);
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // got 200 - new image. store in caches
        NLOG(@"GET %@ If-Modified-Since %@: status 200", url, lastModDate);
        NSString* lastModified = operation.response.allHeaderFields[@"Last-Modified"];
        
        [self storeInCache:responseObject lastModified:lastModified forKey:key];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NLOG(@"GET %@ If-Modified-Since %@: status %d", url, lastModDate, operation.response.statusCode);
        if (operation.response.statusCode == 304)
        {
            // not modified - update check date
            [self setNextCheck:card.code withTimeIntervalFromNow:SUCCESS_INTERVAL];
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
    
    [[TMCache sharedCache] setObject:image forKey:key];
}

-(void) setNextCheck:(NSString*)key withTimeIntervalFromNow:(NSTimeInterval)interval
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* dict = [[settings objectForKey:NEXT_CHECK] mutableCopy];

    NSTimeInterval nextCheck = [NSDate timeIntervalSinceReferenceDate];
    nextCheck += interval;
    [dict setObject:[NSDate dateWithTimeIntervalSinceReferenceDate:nextCheck] forKey:key];
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

@end

