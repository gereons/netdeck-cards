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

#define SEC_PER_DAY     (24 * 60 * 60)

@implementation ImageCache

static ImageCache* instance;

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
    // NSLog(@"get img for %@", card.code);
    UIImage* img = [[TMCache sharedCache] objectForKey:card.code];
    if (img)
    {
        // NSLog(@"cached, check for update");
        [self checkForImageUpdate:card];
        
        if (successBlock)
        {
            successBlock(card, img);
        }
        
        return;
    }
    
    if (![AFNetworkReachabilityManager sharedManager].reachable)
    {
        NSLog(@"offline...");
        // TODO
        successBlock(card, [UIImage imageNamed:@"CardPlaceholder"]);
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
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // download successful
             
             // invoke callback
             if (successBlock)
             {
                 successBlock(card, responseObject);
             }
             
             NSString* lastModified = operation.response.allHeaderFields[@"Last-Modified"];
             [self storeInCache:responseObject lastModified:lastModified forKey:card.code];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             if (failureBlock)
             {
                 NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
                 failureBlock(card, response.statusCode);
             }
         }];
}

-(void) checkForImageUpdate:(Card*)card
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    NSDate* nextCheck;
    NSDictionary* dict = [settings objectForKey:NEXT_CHECK];
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
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // got 200 - new image. store in caches
        NSString* lastModified = operation.response.allHeaderFields[@"Last-Modified"];
        
        [self storeInCache:responseObject lastModified:lastModified forKey:card.code];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 304)
        {
            // not modified - update check date
            [self setNextCheck:card.code];
        }
    }];
    
    [operation start];
}

-(void) storeInCache:(UIImage*)image lastModified:(NSString*)lastModified forKey:(NSString*)key
{
    // NSLog(@"store img for %@", key);
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
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
    
    [self setNextCheck:key];
    
    [[TMCache sharedCache] setObject:image forKey:key];
}

-(void) setNextCheck:(NSString*)key
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* dict = [[settings objectForKey:NEXT_CHECK] mutableCopy];
    if (!dict)
    {
        dict = [NSMutableDictionary dictionary];
    }

    NSTimeInterval nextCheck = [NSDate timeIntervalSinceReferenceDate];
    nextCheck += 30 * SEC_PER_DAY;
    [dict setObject:[NSDate dateWithTimeIntervalSinceReferenceDate:nextCheck] forKey:key];
    [settings setObject:dict forKey:NEXT_CHECK];
}

@end

