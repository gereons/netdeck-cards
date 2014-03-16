//
//  DataDownload.m
//  NRDB
//
//  Created by Gereon Steffens on 24.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <AFNetworking.h>

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

@property UIAlertView* alert;
@property UIProgressView* progressView;
@property NSMutableArray* cards;
@end

@implementation DataDownload
    
+(void) downloadCardData
{
    [[DataDownload sharedInstance] downloadCardData];
}

+(void) downloadAllImages
{
    [[DataDownload sharedInstance] downloadAllImages];
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
    self.alert = [[UIAlertView alloc] initWithTitle:l10n(@"Downloading Card Data") message:nil delegate:self cancelButtonTitle:@"Stop" otherButtonTitles:nil];
    UIActivityIndicatorView* act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [act startAnimating];
    [self.alert setValue:act forKey:@"accessoryView"];
    [self.alert show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self performSelector:@selector(doDownloadCardData) withObject:nil afterDelay:0.01];
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
    
    [self.manager GET:cardsUrl parameters:parameters
        success:^(AFHTTPRequestOperation* operation, id responseObject) {
            if (!self.downloadStopped)
            {
                ok = [CardData setupFromNetrunnerDbApi:responseObject];
            }
            [self downloadFinished:ok];
        }
        failure:^(AFHTTPRequestOperation* operation, NSError* error) {
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:l10n(@"Unable to download cards at this time. Please try again later.")
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self userInfo:@{ @"success": @(ok) }];
}

#pragma mark image download

-(void) downloadAllImages
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 250, 20)];
    
    self.alert = [[UIAlertView alloc] initWithTitle:l10n(@"Downloading Images") message:nil delegate:self cancelButtonTitle:@"Stop" otherButtonTitles:nil];
    [self.alert setValue:self.progressView forKey:@"accessoryView"];
    [self.alert show];
    
    self.downloadStopped = NO;
    self.downloadErrors = 0;
    
    self.cards = [[Card allCards] mutableCopy];
    [self.cards addObjectsFromArray:[Card altCards]];
    
    [self downloadImageForCard:@(0)];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}
    
-(void) downloadImageForCard:(NSNumber*)index
{
    if (self.downloadStopped)
    {
        return;
    }
    
    int i = [index intValue];
    if (i < self.cards.count)
    {
        Card* card = [self.cards objectAtIndex:i];
        
        [[ImageCache sharedInstance] getImageFor:card success:^(Card* card, UIImage* image) {
            [self downloadNextImage:i+1];
        }
        failure:^(Card* card, UIImage* placeholder) {
            ++self.downloadErrors;
            [self downloadNextImage:i+1];
        }
        forced:YES];
    }
}
    
- (void) downloadNextImage:(int)i
{
    if (i < self.cards.count)
    {
        float progress = (i * 100.0) / self.cards.count;
        // NSLog(@"%@ - progress %.1f", card.name, progress);
        
        self.progressView.progress = progress/100.0;
        
        // use -performSelector: so the hud can refresh
        [self performSelector:@selector(downloadImageForCard:) withObject:@(i) afterDelay:.01];
    }
    else
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.alert dismissWithClickedButtonIndex:0 animated:NO];
        if (self.downloadErrors > 0)
        {
            NSString* msg = [NSString stringWithFormat:l10n(@"%d of %lu images could not be downloaded."), self.downloadErrors, (unsigned long)self.cards.count];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
        self.cards = nil;
    }
}

#pragma mark alert dismissal
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (buttonIndex != -1)
    {
        self.downloadStopped = YES;
    }
    self.alert = nil;
    
    [self.manager.operationQueue cancelAllOperations];
}

@end
