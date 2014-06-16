//
//  DataDownload.m
//  NRDB
//
//  Created by Gereon Steffens on 24.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <AFNetworking.h>
#import <EXTScope.h>
#import <SDCAlertView.h>

#import "DataDownload.h"
#import "CardData.h"
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, SDCAlertViewWidth, 20)];
    UIActivityIndicatorView* act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    act.center = CGPointMake(SDCAlertViewWidth/2, view.frame.size.height/2);
    [act startAnimating];
    [view addSubview:act];
    
    self.alert = [SDCAlertView alertWithTitle:l10n(@"Downloading Card Data")
                                      message:nil
                                      subview:view
                                      buttons:@[l10n(@"Stop")]];
    self.alert.delegate = self;
    
    [self performSelector:@selector(doDownloadCardData) withObject:nil afterDelay:0.001];
}
    
-(void) doDownloadCardData
{
    NSString* cardsUrl = @"http://netrunnerdb.com/api/cards";
    NSString* language = [[NSUserDefaults standardUserDefaults] objectForKey:LANGUAGE];
    NSDictionary* parameters = nil;
    if (language.length)
    {
        parameters = @{ @"_locale" : language };
    }
    BOOL __block ok = NO;
    self.downloadStopped = NO;
    
    self.manager = [AFHTTPRequestOperationManager manager];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    @weakify(self);
    [self.manager GET:cardsUrl parameters:parameters
        success:^(AFHTTPRequestOperation* operation, id responseObject) {
            @strongify(self);
            if (!self.downloadStopped)
            {
                ok = [CardData setupFromNetrunnerDbApi:responseObject];
            }
            
            if ([language isEqualToString:@"en"])
            {
                [CardData addEnglishNames:nil];
                [self downloadFinished:ok];
            }
            else
            {
                // download english data as well
                [self.manager GET:cardsUrl parameters:@{ @"_locale": @"en" }
                      success:^(AFHTTPRequestOperation *operation, id responseObject)
                      {
                          [CardData addEnglishNames:responseObject];
                          [self downloadFinished:ok];
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error)
                      {
                          @strongify(self);
                          [self downloadFinished:NO];
                      }];
            }
        }
        failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            @strongify(self);
            // NSLog(@"download failed %@", operation);
            [self downloadFinished:NO];
        }
    ];
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
    self.cards = [[Card allCards] mutableCopy];
    [self.cards addObjectsFromArray:[Card altCards]];
    
    if (self.cards.count == 0)
    {
        [SDCAlertView alertWithTitle:l10n(@"No Card Data")
                             message:l10n(@"Please download card data first")
                             buttons:@[l10n(@"OK")]];
        
        return;
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 250, 20)];
    self.progressView.center = CGPointMake(SDCAlertViewWidth/2, 10);
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, SDCAlertViewWidth, 20)];
    
    [view addSubview:self.progressView];
    
    self.alert = [SDCAlertView alertWithTitle:l10n(@"Downloading Images")
                                      message:[NSString stringWithFormat:l10n(@"Image %d of %d"), 1, self.cards.count]
                                      subview:view
                                      buttons:@[l10n(@"Stop")]];
    self.alert.delegate = self;
    
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
            if (!ok)
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
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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

#pragma mark alert dismissal
- (void) alertView:(SDCAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        self.downloadStopped = YES;
        [self.manager.operationQueue cancelAllOperations];
    }
    self.alert = nil;
}

@end
