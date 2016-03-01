//
//  DataDownload.m
//  Net Deck
//
//  Created by Gereon Steffens on 24.02.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import PromiseKit;
@import SDCAlertView;
@import AFNetworking;
@import PromiseKit_AFNetworking;

#import "EXTScope.h"
#import "DataDownload.h"
#import "ImageCache.h"

@interface DataDownload()

@property int downloadErrors;
@property BOOL downloadStopped;

@property AFHTTPRequestOperationManager *manager;

@property SDCAlertController* alert;
@property UIProgressView* progressView;
@property NSArray* cards;

@property NSArray* localizedCards;
@property NSArray* englishCards;
@property NSArray* localizedSets;

@end

typedef NS_ENUM(NSInteger, DownloadScope)
{
    DownloadAll,
    DownloadMissing
};

@implementation DataDownload
    
+(void) downloadCardData
{
    [[DataDownload sharedInstance] downloadCardAndSetsData];
}

+(void) downloadAllImages
{
    [[DataDownload sharedInstance] downloadImages:DownloadAll];
}

+(void) downloadMissingImages
{
    [[DataDownload sharedInstance] downloadImages:DownloadMissing];
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
    NSString* nrdbHost = [settings stringForKey:SettingsKeys.NRDB_HOST];
    
    if (nrdbHost.length == 0)
    {
        [UIAlertController alertWithTitle:nil message:l10n(@"No known NetrunnerDB server") button:l10n(@"OK")];
        return;
    }

    [self showDownloadAlert];
    [self performSelector:@selector(doDownloadCardData:) withObject:nil afterDelay:0.01];
}

-(void) showDownloadAlert
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    self.alert = [[SDCAlertController alloc] initWithTitle:l10n(@"Downloading Card Data") message:nil preferredStyle:AlertControllerStyleAlert];

    UIActivityIndicatorView* act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [act startAnimating];
    act.translatesAutoresizingMaskIntoConstraints = NO;
    [self.alert.contentView addSubview:act];
    [act.centerXAnchor constraintEqualToAnchor:self.alert.contentView.centerXAnchor].active = YES;
    [act.topAnchor constraintEqualToAnchor:self.alert.contentView.topAnchor].active = YES;
    [act.bottomAnchor constraintEqualToAnchor:self.alert.contentView.bottomAnchor].active = YES;
    
    self.downloadStopped = NO;
    self.downloadErrors = 0;
    
    [self.alert addAction:[[SDCAlertAction alloc] initWithTitle:l10n(@"Stop") style:AlertActionStyleDefault handler:^(SDCAlertAction * action) {
        [self stopDownload];
    }]];
    
    [self.alert presentAnimated:NO completion:nil];
}
    
-(void) doDownloadCardData:(id)dummy
{
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:nil];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* nrdbHost = [settings stringForKey:SettingsKeys.NRDB_HOST];
    NSString* language = [settings stringForKey:SettingsKeys.LANGUAGE];
    
    NSString* cardsUrl = [NSString stringWithFormat:@"http://%@/api/cards/", nrdbHost];
    NSString* setsUrl = [NSString stringWithFormat:@"http://%@/api/sets/", nrdbHost];
    
    NSDictionary* userLocale = @{ @"_locale" : language};
    NSDictionary* englishLocale = @{ @"_locale" : @"en" };
    
    self.localizedCards = nil;
    self.englishCards = nil;
    self.localizedSets = nil;
    
    AFPromise* promise = [self.manager GET:cardsUrl parameters:userLocale];
    
    promise.then(^(id responseObject, AFHTTPRequestOperation *operation){
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
    BOOL ok = self.localizedCards != nil
        && self.englishCards != nil
        && self.localizedSets != nil
        && self.downloadErrors == 0;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.alert dismissAnimated:NO completion:^{
        if (self.downloadStopped) {
            return;
        }
        
        if (!ok)
        {
            [UIAlertController alertWithTitle:nil
                                      message:l10n(@"Unable to download cards at this time. Please try again later.")
                                       button:l10n(@"OK")];
            return;
        } else {
            [CardManager setupFromNrdbApi:self.localizedCards];
            [CardManager addAdditionalNames:self.englishCards saveFile:YES];
            [CardSets setupFromNrdbApi:self.localizedSets];
            [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.LOAD_CARDS object:self userInfo:@{ @"success": @(ok) }];
        }
    }];
    
    self.alert = nil;
}


#pragma mark image download

-(void) downloadImages:(DownloadScope)scope
{
    self.cards = [CardManager allCards];
    if (scope == DownloadMissing)
    {
        NSMutableArray* missing = [NSMutableArray array];
        for (Card* card in self.cards)
        {
            if (![[ImageCache sharedInstance] imageAvailableFor:card])
            {
                [missing addObject:card];
            }
        }
        self.cards = missing;
    }
    
    if (self.cards.count == 0)
    {
        if (scope == DownloadAll)
        {
            [UIAlertController alertWithTitle:l10n(@"No Card Data")
                                      message:l10n(@"Please download card data first")
                                       button:l10n(@"OK")];
        }
        else
        {
            [UIAlertController alertWithTitle:nil
                                      message:l10n(@"No missing card images")
                                       button:l10n(@"OK")];
        }
        
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progress = 0;
    
    [self.progressView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSString* msg = [NSString stringWithFormat:l10n(@"Image %d of %d"), 1, self.cards.count];
    self.alert = [[SDCAlertController alloc] initWithTitle:@"Downloading Images" message:nil preferredStyle:AlertControllerStyleAlert];
    
    NSDictionary* attrs = @{ NSFontAttributeName: [UIFont md_systemFontOfSize:12] };
    self.alert.attributedMessage = [[NSAttributedString alloc] initWithString:msg attributes:attrs];
    // self.alert.messageLabelFont = [UIFont md_systemFontOfSize:12];
    
    [self.alert.contentView addSubview:self.progressView];
    
    [self.progressView sdc_pinWidthToWidthOfView:self.alert.contentView offset:-20];
    [self.progressView sdc_centerInSuperview];
    
    [self.alert addAction:[[SDCAlertAction alloc] initWithTitle:l10n(@"Stop") style:AlertActionStyleDefault handler:^(SDCAlertAction * action) {
        [self stopDownload];
    }]];
    
    [self.alert presentAnimated:NO completion:nil];
    
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
        
        if (scope == DownloadAll)
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
    
        NSDictionary* attrs = @{ NSFontAttributeName: [UIFont md_systemFontOfSize:12] };
        NSString* msg = [NSString stringWithFormat:l10n(@"Image %d of %d"), index+1, self.cards.count ];
        self.alert.attributedMessage = [[NSAttributedString alloc] initWithString:msg attributes:attrs];
        
        // use -performSelector: so the UI can refresh
        [self performSelector:@selector(downloadImageForCard:) withObject:dict afterDelay:.001];
    }
    else
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        [self.alert dismissAnimated:NO completion:nil];
        self.alert = nil;
        if (self.downloadErrors > 0)
        {
            NSString* msg = [NSString stringWithFormat:l10n(@"%d of %lu images could not be downloaded."), self.downloadErrors, (unsigned long)self.cards.count];
            
            [UIAlertController alertWithTitle:nil message:msg button:l10n(@"OK")];
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
