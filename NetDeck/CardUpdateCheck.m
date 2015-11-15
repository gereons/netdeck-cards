//
//  CardUpdateCheck.m
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>
#import <AFNetworkReachabilityManager.h>

#import "CardUpdateCheck.h"
#import "CardManager.h"
#import "DataDownload.h"
#import "SettingsKeys.h"

@implementation CardUpdateCheck

+(void) checkCardsAvailable
{
    // check if card data is available at all, and if so, if it maybe needs an update
    if (![CardManager cardsAvailable] || ![CardSets setsAvailable])
    {
        SDCAlertView* alert = [SDCAlertView alertWithTitle:l10n(@"No Card Data")
                                                   message:l10n(@"To use this app, you must first download card data.")
                                                   buttons:@[l10n(@"Not now"), l10n(@"Download")]];
        
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 1)
            {
                [DataDownload downloadCardData];
            }
        };
    }
    else
    {
        [CardUpdateCheck checkCardUpdate];
    }

}

+(void) checkCardUpdate
{
    NSString* next = [[NSUserDefaults standardUserDefaults] stringForKey:NEXT_DOWNLOAD];
    
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setDateStyle:NSDateFormatterShortStyle];
    [fmt setTimeStyle:NSDateFormatterNoStyle];
    
    NSDate* scheduled = [fmt dateFromString:next];
    if (scheduled == nil)
    {
        return;
    }
    
    NSDate* now = [NSDate date];
    
    if (APP_ONLINE && [scheduled compare:now] == NSOrderedAscending)
    {
        SDCAlertView* alert = [SDCAlertView alertWithTitle:l10n(@"Update cards")
                                                   message:l10n(@"Card data may be out of date. Download now?")
                                                   buttons:@[l10n(@"Later"), l10n(@"OK")]];
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 0) // later
            {
                // ask again tomorrow
                NSDate* next = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
                
                [[NSUserDefaults standardUserDefaults] setObject:[fmt stringFromDate:next] forKey:NEXT_DOWNLOAD];
            }
            if (buttonIndex == 1) // ok
            {
                [DataDownload downloadCardData];
            }
        };
    }
}

@end
