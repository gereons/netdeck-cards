//
//  DataDownload.m
//  NRDB
//
//  Created by Gereon Steffens on 24.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <EXTScope.h>
#import <SDCAlertView.h>
#import <UIView+SDCAutoLayout.h>

#import "DataDownload.h"
#import "CardManager.h"
#import "CardSets.h"
#import "Card.h"
#import "ImageCache.h"
#import "SettingsKeys.h"
#import "Notifications.h"

@interface DataDownload()

@property int downloadErrors;
@property BOOL downloadStopped;

@property AFHTTPRequestOperationManager *manager;

@property SDCAlertView* alert;
@property UIProgressView* progressView;
@property NSMutableArray* cards;
@end

typedef NS_ENUM(NSInteger, DownloadScope)
{
    ALL,
    MISSING
};

@implementation DataDownload
    
+(void) downloadCardData
{
    [[DataDownload sharedInstance] downloadCardData];
}

+(void) downloadAllImages
{
    [[DataDownload sharedInstance] downloadImages:ALL];
}

+(void) downloadMissingImages
{
    [[DataDownload sharedInstance] downloadImages:MISSING];
}

static DataDownload* instance;
+(DataDownload*) sharedInstance
{
    if (instance == nil)
    {
        instance = [DataDownload new];
    }
    return instance;
}

#pragma mark card data download

-(void) downloadCardData
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* nrdbHost = [settings objectForKey:NRDB_HOST];
    NSString* cardsUrl = [settings objectForKey:CARDS_ENDPOINT];
    NSString* lockpickCode = [settings objectForKey:LOCKPICK_CODE];
    
    if (nrdbHost.length == 0 && cardsUrl.length == 0 && lockpickCode.length == 0)
    {
        [SDCAlertView alertWithTitle:nil message:l10n(@"Please enter a Server Name, Cards Endpoint URL, and/or a Lockpick code") buttons:@[l10n(@"OK")]];
        return;
    }

    if (cardsUrl.length == 0 && nrdbHost.length == 0)
    {
        // fetch a datasucker url from lockpic
        [self showDownloadAlert];
        NSString* code = [lockpickCode stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        NSString* lockpickUrl =[NSString stringWithFormat:@"https://lockpick.parseapp.com/datasucker/%@", code];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:lockpickUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString* url;
            if ([responseObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* dict = responseObject;
                url = dict[@"url"];
            }
            if (url.length > 0)
            {
                BOOL http = [url hasPrefix:@"http://"] || [url hasPrefix:@"https://"];
                if (!http)
                {
                    url = [NSString stringWithFormat:@"http://%@", url];
                }
                url = [NSString stringWithFormat:@"%@/cards", url];
                
                if (!self.downloadStopped)
                {
                    [self startDownloadCardData:url];
                }
            }
            else
            {
                [self showLockpickError];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self showLockpickError];
        }];
    }
    else
    {
        if (nrdbHost.length)
        {
            cardsUrl = [NSString stringWithFormat:@"http://%@/api/cards/", nrdbHost];
        }
        [self showDownloadAlert];
        [self startDownloadCardData:cardsUrl];
    }
}

-(void) showLockpickError
{
    [SDCAlertView alertWithTitle:nil message:l10n(@"Lockpick request failed") buttons:@[l10n(@"OK")]];
}

-(void) showDownloadAlert
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    UIActivityIndicatorView* act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [act startAnimating];
    [act setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.alert = [[SDCAlertView alloc] initWithTitle:l10n(@"Downloading Card Data")
                                             message:nil
                                            delegate:nil
                                   cancelButtonTitle:l10n(@"Stop")
                                   otherButtonTitles:nil];
    
    [self.alert.contentView addSubview:act];
    
    self.downloadStopped = NO;
    self.downloadErrors = 0;
    
    [act sdc_centerInSuperview];
    @weakify(self);
    [self.alert showWithDismissHandler:^(NSInteger buttonIndex) {
        @strongify(self);
        [self stopDownload];
    }];
}

-(void) startDownloadCardData:(NSString*)url
{
    [self performSelector:@selector(doDownloadCardData:) withObject:url afterDelay:0.001];
}
    
-(void) doDownloadCardData:(NSString*)cardsUrl
{
    BOOL __block ok = NO;
    self.downloadStopped = NO;
    
    self.manager = [AFHTTPRequestOperationManager manager];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                                 URLString:cardsUrl
                                                                                parameters:nil
                                                                                     error:nil];
    // bypass cache!
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    @weakify(self);
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request
      success:^(AFHTTPRequestOperation* operation, id responseObject) {
          @strongify(self);
          if (!self.downloadStopped)
          {
              ok = [CardManager setupFromDatasuckerApi:responseObject];
          }
          [self downloadFinished:ok];
      } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
          @strongify(self);
          // NSLog(@"download failed %@", operation);
          [self downloadFinished:NO];
      }];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation start];
}

-(void) downloadFinished:(BOOL)ok
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.alert dismissWithClickedButtonIndex:-1 animated:NO];
    
    if (!ok && !self.downloadStopped)
    {
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Unable to download cards at this time. Please try again later.")
                             buttons:@[l10n(@"OK")]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self userInfo:@{ @"success": @(ok) }];
}

#pragma mark image download

-(void) downloadImages:(DownloadScope)scope
{
    self.cards = [[CardManager allCards] mutableCopy];
    
    if (self.cards.count == 0)
    {
        [SDCAlertView alertWithTitle:l10n(@"No Card Data")
                             message:l10n(@"Please download card data first")
                             buttons:@[l10n(@"OK")]];
        
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progress = 0;
    
    [self.progressView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.alert = [[SDCAlertView alloc] initWithTitle:l10n(@"Downloading Images")
                                             message:[NSString stringWithFormat:l10n(@"Image %d of %d"), 1, self.cards.count]
                                            delegate:nil
                                   cancelButtonTitle:l10n(@"Stop")
                                   otherButtonTitles: nil];

    [self.alert.contentView addSubview:self.progressView];
    
    [self.progressView sdc_pinWidthToWidthOfView:self.alert.contentView offset:-20];
    [self.progressView sdc_centerInSuperview];
    
    @weakify(self);
    [self.alert showWithDismissHandler:^(NSInteger buttonIndex) {
        @strongify(self);
        [self stopDownload];
    }];
    
    self.downloadStopped = NO;
    self.downloadErrors = 0;
    
    [self downloadImageForCard:@{ @"index": @(0), @"scope": @(scope)} ];
}
    
-(void) downloadImageForCard:(NSDictionary*)dict
{
    int index = [dict[@"index"] intValue];
    DownloadScope scope = [dict[@"scope"] intValue];
    
    if (self.downloadStopped)
    {
        return;
    }
    
    if (index < self.cards.count)
    {
        Card* card = [self.cards objectAtIndex:index];
        
        @weakify(self);
        UpdateCompletionBlock downloadNext = ^(BOOL ok) {
            @strongify(self);
            if (!ok && card.imageSrc != nil)
            {
                ++self.downloadErrors;
            }
            [self downloadNextImage:@{ @"index": @(index+1), @"scope": @(scope)}];
        };
        
        if (scope == ALL)
        {
            [[ImageCache sharedInstance] updateImageFor:card completion:downloadNext];
        }
        else
        {
            [[ImageCache sharedInstance] updateMissingImageFor:card completion:downloadNext];
        }
    }
}
    
- (void) downloadNextImage:(NSDictionary*)dict
{
    int index = [dict[@"index"] intValue];
    if (index < self.cards.count)
    {
        float progress = (index * 100.0) / self.cards.count;
        // NSLog(@"%@ - progress %.1f", card.name, progress);
        
        self.progressView.progress = progress/100.0;
        
        self.alert.message = [NSString stringWithFormat:l10n(@"Image %d of %d"), index+1, self.cards.count ];
        
        // use -performSelector: so the UI can refresh
        [self performSelector:@selector(downloadImageForCard:) withObject:dict afterDelay:.001];
    }
    else
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.alert dismissWithClickedButtonIndex:99 animated:NO];
        if (self.downloadErrors > 0)
        {
            NSString* msg = [NSString stringWithFormat:l10n(@"%d of %lu images could not be downloaded."), self.downloadErrors, (unsigned long)self.cards.count];
            
            [SDCAlertView alertWithTitle:nil message:msg buttons:@[l10n(@"OK")]];
        }
        
        self.cards = nil;
    }
}

- (void) stopDownload
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    self.downloadStopped = YES;
    [self.manager.operationQueue cancelAllOperations];
    
    self.alert = nil;
}

@end
