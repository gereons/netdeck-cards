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

#define LAST_MOD_CACHE  @"lastModified"
#define NEXT_CHECK      @"nextCheck"

#define SEC_PER_DAY         (24 * 60 * 60)
#define SUCCESS_INTERVAL    (30*SEC_PER_DAY)
#define ERROR_INTERVAL      (1*SEC_PER_DAY)

#define NETWORK_LOG         0

#if NETWORK_LOG
#define NLOG(fmt, ...)      do { NSLog(fmt, ##__VA_ARGS__); } while(0)
#else
#define NLOG(...)           do {} while(0)
#endif


@implementation ImageCache

static ImageCache* instance;
static UIImage* runnerPlaceholder;
static UIImage* corpPlaceholder;

#define PLACEHOLDER(card)   (card.role == NRRoleRunner ? runnerPlaceholder : corpPlaceholder)

+(void) initialize
{
    runnerPlaceholder = [UIImage imageNamed:@"RunnerPlaceholder"];
    corpPlaceholder = [UIImage imageNamed:@"CorpPlaceholder"];
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
    [settings removeObjectForKey:LAST_MOD_CACHE];
    [settings removeObjectForKey:NEXT_CHECK];
    
    [[TMCache sharedCache] removeAllObjects];
}

-(void) getImageFor:(Card *)card success:(SuccessCompletionBlock)successBlock failure:(ErrorCompletionBlock)failureBlock
{
    [self getImageFor:card success:successBlock failure:failureBlock forced:NO];
}

-(void) getImageFor:(Card *)card success:(SuccessCompletionBlock)successBlock failure:(ErrorCompletionBlock)failureBlock forced:(BOOL)forced
{
    // NSLog(@"get img for %@", card.code);
    UIImage* img = [[TMCache sharedCache] objectForKey:card.code];
    if (img)
    {
        // NSLog(@"cached, check for update");
        [self checkForImageUpdate:card forced:forced];
        
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
        [self downloadImageFor:card success:successBlock failure:failureBlock];
    }
}

-(void) downloadImageFor:(Card *)card success:(SuccessCompletionBlock)successBlock failure:(ErrorCompletionBlock)failureBlock
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
             [self storeInCache:responseObject lastModified:lastModified forKey:card.code];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // download failed
             NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
             NLOG(@"GET %@: error %d", url, response.statusCode);
             
             // invoke callback
             if (failureBlock)
             {
                 failureBlock(card, response.statusCode, PLACEHOLDER(card));
                 
                 [self storeInCache:PLACEHOLDER(card) lastModified:nil forKey:card.code];
             }
         }];
}

-(void) checkForImageUpdate:(Card*)card forced:(BOOL)forced
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    NSDictionary* dict = [settings objectForKey:NEXT_CHECK];
    if (!forced)
    {
        NSDate* nextCheck;
        if (dict)
        {
            nextCheck = [dict objectForKey:card.code];
        }
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
    
    NSString* lastModDate;
    dict = [[settings objectForKey:LAST_MOD_CACHE] mutableCopy];
    if (dict)
    {
        lastModDate = [dict objectForKey:card.code];
    }
    
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
        
        [self storeInCache:responseObject lastModified:lastModified forKey:card.code];
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
        if (!dict)
        {
            dict = [NSMutableDictionary dictionary];
        }
        
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
    if (!dict)
    {
        dict = [NSMutableDictionary dictionary];
    }

    NSTimeInterval nextCheck = [NSDate timeIntervalSinceReferenceDate];
    nextCheck += interval;
    [dict setObject:[NSDate dateWithTimeIntervalSinceReferenceDate:nextCheck] forKey:key];
    [settings setObject:dict forKey:NEXT_CHECK];
}

@end

