//
//  CardUpdateCheck.m
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardUpdateCheck.h"
#import "DataDownload.h"
#import "AppDelegate.h"

@implementation CardUpdateCheck

+(void) checkCardsAvailable:(UIViewController*)vc
{
    // check if card data is available at all, and if so, if it maybe needs an update
    if (![CardManager cardsAvailable] || ![CardSets setsAvailable])
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"No Card Data")
                                                                       message:l10n(@"To use this app, you must first download card data.")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Not now") handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Download") handler:^(UIAlertAction * _Nonnull action) {
            [DataDownload downloadCardData];
        }]];
        
        [vc presentViewController:alert animated:NO completion:nil];
    }
    else
    {
        [CardUpdateCheck checkCardUpdate:vc];
    }

}

+(void) checkCardUpdate:(UIViewController*)vc
{
    NSString* next = [[NSUserDefaults standardUserDefaults] stringForKey:SettingsKeys.NEXT_DOWNLOAD];
    
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle];
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    
    NSDate* scheduled = [fmt dateFromString:next];
    if (scheduled == nil)
    {
        return;
    }
    
    NSDate* now = [NSDate date];
    
    if (AppDelegate.online && [scheduled compare:now] == NSOrderedAscending)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Update cards")
                                                                       message:l10n(@"Card data may be out of date. Download now?")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Later") handler:^(UIAlertAction * _Nonnull action) {
            // ask again tomorrow
            NSDate* next = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
            
            [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:SettingsKeys.NEXT_DOWNLOAD];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction * _Nonnull action) {
            [DataDownload downloadCardData];
        }]];
        
        [vc presentViewController:alert animated:NO completion:nil];
    }
}

@end
