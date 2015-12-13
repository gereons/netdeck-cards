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

#import "AppDelegate.h"
#import <Dropbox/Dropbox.h>
#import "EXTScope.h"
#import "SettingsViewController.h"
#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "DataDownload.h"
#import "ImageCache.h"
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardsLoaded:) name:Notifications.LOAD_CARDS object:nil];
        
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
        [hiddenKeys addObjectsFromArray:@[ SettingsKeys.AUTO_HISTORY, SettingsKeys.CREATE_DECK_ACTIVE ]];
    }
    if (IS_IPAD)
    {
        [hiddenKeys addObjectsFromArray:@[ @"about_hide_1", @"about_hide_2" ]];
    }

#if RELEASE
    [hiddenKeys addObjectsFromArray:@[ NRDB_TOKEN_EXPIRY, REFRESH_AUTH_NOW, LAST_BG_FETCH ]];
#endif
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if (![settings boolForKey:SettingsKeys.USE_DROPBOX])
    {
        [hiddenKeys addObject:SettingsKeys.AUTO_SAVE_DB];
    }
    if (![settings boolForKey:SettingsKeys.USE_NRDB])
    {
        [hiddenKeys addObjectsFromArray:@[ SettingsKeys.NRDB_TOKEN_EXPIRY, SettingsKeys.REFRESH_AUTH_NOW ]];
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
    
    if ([notification.object isEqualToString:SettingsKeys.USE_DROPBOX])
    {
        BOOL useDropbox = [[notification.userInfo objectForKey:SettingsKeys.USE_DROPBOX] boolValue];
        
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
    
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DROPBOX_CHANGED object:self];
        [self refresh];
    }
    else if ([notification.object isEqualToString:SettingsKeys.USE_NRDB])
    {
        BOOL useNrdb = [[notification.userInfo objectForKey:SettingsKeys.USE_NRDB] boolValue];
        
        if (useNrdb)
        {
            if (AppDelegate.online)
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
                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:SettingsKeys.USE_NRDB];
            }
        }
        else
        {
            NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
            [settings removeObjectForKey:SettingsKeys.NRDB_ACCESS_TOKEN];
            [settings removeObjectForKey:SettingsKeys.NRDB_REFRESH_TOKEN];
            [settings removeObjectForKey:SettingsKeys.NRDB_TOKEN_EXPIRY];
            [settings removeObjectForKey:SettingsKeys.NRDB_TOKEN_TTL];
            
        }
        [self refresh];
    }
    else if ([notification.object isEqualToString:SettingsKeys.UPDATE_INTERVAL])
    {
        [CardManager setNextDownloadDate];
    }
    else if ([notification.object isEqualToString:SettingsKeys.LANGUAGE])
    {
        [[ImageCache sharedInstance] clearLastModifiedInfo];
    }
}

- (void)settingsViewController:(id)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:SettingsKeys.DOWNLOAD_DATA_NOW])
    {
        if (AppDelegate.online)
        {
            [DataDownload downloadCardData];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:SettingsKeys.REFRESH_AUTH_NOW])
    {
        if (AppDelegate.online)
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
    else if ([specifier.key isEqualToString:SettingsKeys.DOWNLOAD_IMG_NOW])
    {
        if (AppDelegate.online)
        {
            [DataDownload downloadAllImages];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:SettingsKeys.DOWNLOAD_MISSING_IMG])
    {
        if (AppDelegate.online)
        {
            [DataDownload downloadMissingImages];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:SettingsKeys.CLEAR_CACHE])
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
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:SettingsKeys.LAST_DOWNLOAD];
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:SettingsKeys.NEXT_DOWNLOAD];
                [self refresh];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.LOAD_CARDS object:self];
            }
        };
    }
    else if ([specifier.key isEqualToString:SettingsKeys.TEST_API])
    {
        if (AppDelegate.online)
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
    NSString* nrdbHost = [settings stringForKey:SettingsKeys.NRDB_HOST];
    
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
