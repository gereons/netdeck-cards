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
#import <AFNetworking.h>
#import <PromiseKit.h>
#import <PromiseKit-AFNetworking/AFNetworking+PromiseKit.h>

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
@property NSArray* cards;

@property NSArray* localizedCards;
@property NSArray* englishCards;
@property NSArray* localizedSets;

@end

typedef NS_ENUM(NSInteger, DownloadScope)
{
    ALL,
    MISSING
};

@implementation DataDownload
    
+(void) downloadCardData
{
    [[DataDownload sharedInstance] downloadCardAndSetsData];
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

-(void) downloadCardAndSetsData
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* nrdbHost = [settings objectForKey:NRDB_HOST];
    
    if (nrdbHost.length == 0)
    {
        [SDCAlertView alertWithTitle:nil message:l10n(@"No known NetrunnerDB server") buttons:@[l10n(@"OK")]];
        return;
    }

    [self showDownloadAlert];
    [self performSelector:@selector(doDownloadCardData:) withObject:nil afterDelay:0.01];
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
    [self.alert showWithDismissHandler:^(NSInteger buttonIndex) {
        if (buttonIndex != -1)
        {
            [self stopDownload];
        }
    }];
}
    
-(void) doDownloadCardData:(id)dummy
{
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:nil];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* nrdbHost = [settings objectForKey:NRDB_HOST];
    NSString* language = [settings objectForKey:LANGUAGE];
    
    NSString* cardsUrl = [NSString stringWithFormat:@"http://%@/api/cards/", nrdbHost];
    NSString* setsUrl = [NSString stringWithFormat:@"http://%@/api/sets/", nrdbHost];
    
    NSDictionary* userLocale = @{ @"_locale" : language};
    NSDictionary* englishLocale = @{ @"_locale" : @"en" };
    
    self.localizedCards = nil;
    self.englishCards = nil;
    self.localizedSets = nil;
    
    [self.manager GET:cardsUrl parameters:userLocale]
    .then(^(id responseObject, AFHTTPRequestOperation *operation){
        // NSLog(@"1st request completed for operation: %@", operation.request.description);
        // NSLog(@"1st result %d elements", [responseObject count]);
        self.localizedCards = responseObject;
        if (self.downloadStopped)
        {
            @throw @"stopped 1";
        }
        return [self.manager GET:cardsUrl parameters:englishLocale];
    }).then(^(id responseObject, AFHTTPRequestOperation *operation){
        // NSLog(@"2nd request completed for operation: %@", operation.request.description);
        // NSLog(@"2nd result %d elements", [responseObject count]);
        self.englishCards = responseObject;
        if (self.downloadStopped)
        {
            @throw @"stopped 2";
        }
        return [self.manager GET:setsUrl parameters:userLocale];
    }).then(^(id responseObject, AFHTTPRequestOperation *operation){
        // NSLog(@"3rd request completed for operation: %@", operation.request.description);
        // NSLog(@"3rd result %d elements", [responseObject count]);
        self.localizedSets = responseObject;
        if (self.downloadStopped)
        {
            @throw @"stopped 3";
        }
    }).catch(^(NSError *error){
        // NSLog(@"error happened: %@", error.localizedDescription);
        // NSLog(@"original operation: %@", error.userInfo[AFHTTPRequestOperationErrorKey]);
        ++self.downloadErrors;
    }).finally(^{
        // NSLog(@"downloads finished 1, stopped = %d", self.downloadStopped);
        [self finishDownloads];
    });
}

-(void) finishDownloads
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.alert dismissWithClickedButtonIndex:-1 animated:NO];
    
    BOOL ok = self.localizedCards != nil
            && self.englishCards != nil
            && self.localizedSets != nil
            && self.downloadErrors == 0;
    
    if (!ok && !self.downloadStopped)
    {
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Unable to download cards at this time. Please try again later.")
                             buttons:@[l10n(@"OK")]];
        return;
    }
    
    [CardManager setupFromNrdbApi:self.localizedCards];
    [CardManager addEnglishNames:self.englishCards saveFile:YES];
    [CardSets setupFromNrdbApi:self.localizedSets];
    
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
