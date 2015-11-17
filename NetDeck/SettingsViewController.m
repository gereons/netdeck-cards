//
//  SettingsViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 27.03.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@import SVProgressHUD;
@import SDCAlertView;
@import AFNetworking;

#import <Dropbox/Dropbox.h>
#import "EXTScope.h"
#import "SettingsViewController.h"
#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "DataDownload.h"
#import "CardManager.h"
#import "ImageCache.h"
#import "SettingsKeys.h"
#import "Notifications.h"
#import "NRDBAuthPopupViewController.h"
#import "NRDB.h"

@implementation SettingsViewController

-(id) init
{
    if ((self = [super init]))
    {
        self->_iask = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        self.iask.delegate = self;
        self.iask.showDoneButton = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:kIASKAppSettingChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardsLoaded:) name:LOAD_CARDS object:nil];
        
        [self refresh];
    }
    return self;
}

-(void) dealloc
{
    self->_iask.delegate = nil;
    self->_iask = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) refresh
{
    NSMutableSet* hiddenKeys = [NSMutableSet set];
    if (![CardManager cardsAvailable] || ![CardSets setsAvailable])
    {
        [hiddenKeys addObjectsFromArray:@[ @"sets_hide_1", @"sets_hide_2" ]];
    }
    if (IS_IPHONE)
    {
        [hiddenKeys addObjectsFromArray:@[ AUTO_HISTORY, CREATE_DECK_ACTIVE ]];
    }
    if (IS_IPAD)
    {
        [hiddenKeys addObjectsFromArray:@[ @"about_hide_1", @"about_hide_2" ]];
    }

#if RELEASE
    [hiddenKeys addObjectsFromArray:@[ NRDB_TOKEN_EXPIRY, REFRESH_AUTH_NOW, LAST_BG_FETCH ]];
#endif
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if (![settings boolForKey:USE_DROPBOX])
    {
        [hiddenKeys addObject:AUTO_SAVE_DB];
    }
    if (![settings boolForKey:USE_NRDB])
    {
        [hiddenKeys addObjectsFromArray:@[ NRDB_TOKEN_EXPIRY, REFRESH_AUTH_NOW ]];
    }
    [self.iask setHiddenKeys:hiddenKeys];
}

- (void) cardsLoaded:(NSNotification*) notification
{
    if ([[notification.userInfo objectForKey:@"success"] boolValue])
    {
        [self refresh];
    }
}

- (void) settingsChanged:(NSNotification*)notification
{
    // NSLog(@"changing %@ to %@", notification.object, notification.userInfo);
    
    if ([notification.object isEqualToString:USE_DROPBOX])
    {
        BOOL useDropbox = [[notification.userInfo objectForKey:USE_DROPBOX] boolValue];
        
        @try
        {
            DBAccountManager* accountManager = [DBAccountManager sharedManager];
            DBAccount *account = accountManager.linkedAccount;
            
            if (useDropbox)
            {
                if (!account)
                {
                    UIViewController* topMost = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
                    [accountManager linkFromController:topMost];
                }
            }
            else
            {
                if (account)
                {
                    [account unlink];
                    [DBFilesystem setSharedFilesystem:nil];
                }
        }
        }
        @catch (DBException* dbEx)
        {}
    
        [[NSNotificationCenter defaultCenter] postNotificationName:DROPBOX_CHANGED object:self];
        [self refresh];
    }
    else if ([notification.object isEqualToString:USE_NRDB])
    {
        BOOL useNrdb = [[notification.userInfo objectForKey:USE_NRDB] boolValue];
        
        if (useNrdb)
        {
            if (APP_ONLINE)
            {
                if (IS_IPAD)
                {
                    UIViewController* topMost = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
                    [NRDBAuthPopupViewController showInViewController:topMost];
                }
                else
                {
                    [NRDBAuthPopupViewController pushOn:self.iask.navigationController];
                }
            }
            else
            {
                [self showOfflineAlert];
                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:USE_NRDB];
            }
        }
        else
        {
            NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
            [settings removeObjectForKey:NRDB_ACCESS_TOKEN];
            [settings removeObjectForKey:NRDB_REFRESH_TOKEN];
            [settings removeObjectForKey:NRDB_TOKEN_EXPIRY];
            [settings removeObjectForKey:NRDB_TOKEN_TTL];
            
        }
        [self refresh];
    }
    else if ([notification.object isEqualToString:UPDATE_INTERVAL])
    {
        [CardManager setNextDownloadDate];
    }
    else if ([notification.object isEqualToString:LANGUAGE])
    {
        [[ImageCache sharedInstance] clearLastModifiedInfo];
    }
}

- (void)settingsViewController:(id)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:DOWNLOAD_DATA_NOW])
    {
        if (APP_ONLINE)
        {
            [DataDownload downloadCardData];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:REFRESH_AUTH_NOW])
    {
        if (APP_ONLINE)
        {
            [SVProgressHUD showInfoWithStatus:@"re-authenticating"];
            [[NRDB sharedInstance] backgroundRefreshAuthentication:^(UIBackgroundFetchResult result) {
                [self refresh];
                [SVProgressHUD dismiss];
            }];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:DOWNLOAD_IMG_NOW])
    {
        if (APP_ONLINE)
        {
            [DataDownload downloadAllImages];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:DOWNLOAD_MISSING_IMG])
    {
        if (APP_ONLINE)
        {
            [DataDownload downloadMissingImages];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:CLEAR_CACHE])
    {
        SDCAlertView* alert = [SDCAlertView alertWithTitle:nil
                                                   message:l10n(@"Clear Cache? You will need to re-download all data.")
                                                   buttons:@[l10n(@"No"), l10n(@"Yes") ]];
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 1) // yes, clear
            {
                [[ImageCache sharedInstance] clearCache];
                [CardManager removeFiles];
                [CardSets removeFiles];
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:LAST_DOWNLOAD];
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:NEXT_DOWNLOAD];
                [self refresh];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self];
            }
        };
    }
    else if ([specifier.key isEqualToString:TEST_API])
    {
        if (APP_ONLINE)
        {
            [self testApiSettings];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
}

-(void) testApiSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* nrdbHost = [settings stringForKey:NRDB_HOST];
    
    if (nrdbHost.length == 0)
    {
        [SDCAlertView alertWithTitle:nil message:l10n(@"Please enter a Server Name") buttons:@[l10n(@"OK")]];
        return;
    }

    [SVProgressHUD showWithStatus:l10n(@"Testing...")];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSString* nrdbUrl = [NSString stringWithFormat:@"http://%@/api/cards/", nrdbHost];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:nrdbUrl parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
            BOOL ok = YES;
            if ([responseObject isKindOfClass:[NSArray class]])
            {
                NSArray* arr = responseObject;
                NSDictionary* dict = arr[0];
                if (dict[@"code"] == nil)
                {
                    ok = NO;
                }
            }
             [self finishApiTests:ok];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self finishApiTests:NO];
        }
    ];
}

-(void) finishApiTests:(BOOL)nrdbOk
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    NSString* message = nrdbOk ? l10n(@"NetrunnerDB is OK") : l10n(@"NetrunnerDB is invalid");
    [SDCAlertView alertWithTitle:nil message:message buttons:@[ l10n(@"OK") ]];
}

-(void) showOfflineAlert
{
    [SDCAlertView alertWithTitle:nil
                         message:l10n(@"An Internet connection is required.")
                         buttons:@[l10n(@"OK")]];
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
}

@end
