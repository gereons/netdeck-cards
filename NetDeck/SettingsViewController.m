//
//  SettingsViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 27.03.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import SVProgressHUD;

#import "SettingsViewController.h"
#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "NRDBAuthPopupViewController.h"

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
    if (![CardManager cardsAvailable] || ![PackManager packsAvailable])
    {
        [hiddenKeys addObjectsFromArray:@[ @"sets_hide_1", @"sets_hide_2", SettingsKeys.BROWSER_PACKS, SettingsKeys.DECKBUILDER_PACKS ]];
    }
    if (Device.isIphone)
    {
        [hiddenKeys addObjectsFromArray:@[ SettingsKeys.AUTO_HISTORY, SettingsKeys.CREATE_DECK_ACTIVE ]];
    }
    if (Device.isIpad)
    {
        [hiddenKeys addObjectsFromArray:@[ @"about_hide_1", @"about_hide_2" ]];
    }

#if RELEASE
    [hiddenKeys addObjectsFromArray:@[ SettingsKeys.NRDB_TOKEN_EXPIRY, SettingsKeys.REFRESH_AUTH_NOW, SettingsKeys.LAST_BG_FETCH, SettingsKeys.LAST_REFRESH ]];
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
    
    NSSet* currentlyHidden = self.iask.hiddenKeys;
    if (![currentlyHidden isEqualToSet:hiddenKeys]) {
        [self.iask setHiddenKeys:hiddenKeys];
    }
}

- (void) cardsLoaded:(NSNotification*) notification
{
    if ([[notification.userInfo objectForKey:@"success"] boolValue])
    {
        [self refresh];
        [DeckManager flushCache];
    }
}

- (void) settingsChanged:(NSNotification*)notification
{
    NSString* key = notification.userInfo.allKeys.firstObject;
    // NSLog(@"changing %@ to %@", key, notification.userInfo);
    
    if ([key isEqualToString:SettingsKeys.USE_DROPBOX]) {
        BOOL useDropbox = [[notification.userInfo objectForKey:SettingsKeys.USE_DROPBOX] boolValue];
        
        if (useDropbox) {
            [DropboxWrapper authorizeFromController:self.iask];
        } else {
            [DropboxWrapper unlinkClient];
        }
    
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DROPBOX_CHANGED object:self];
        [self refresh];
    }
    else if ([key isEqualToString:SettingsKeys.USE_NRDB]) {
        BOOL useNrdb = [[notification.userInfo objectForKey:SettingsKeys.USE_NRDB] boolValue];
        
        if (useNrdb) {
            [self nrdbLogin];
        } else {
            [NRDB clearSettings];
            [NRDBHack clearCredentials];
        }
        [self refresh];
    }
    else if ([key isEqualToString:SettingsKeys.USE_JNET]) {
        BOOL useJnet = [[notification.userInfo objectForKey:SettingsKeys.USE_JNET] boolValue];
        
        if (useJnet) {
            [self jnetLogin];
        } else {
            [[JintekiNet sharedInstance] clearCredentials];
        }
        [self refresh];
    }
    else if ([key isEqualToString:SettingsKeys.UPDATE_INTERVAL]) {
        [CardManager setNextDownloadDate];
    }
    else if ([key isEqualToString:SettingsKeys.LANGUAGE]) {
        LOG_EVENT(@"Change Language", @{@"Language": [notification.userInfo objectForKey:SettingsKeys.LANGUAGE]});
        [[ImageCache sharedInstance] clearLastModifiedInfo];
        [DeckManager flushCache];
    }
    else if ([key isEqualToString:SettingsKeys.KEEP_NRDB_CREDENTIALS]) {
        BOOL keep = [[notification.userInfo objectForKey:SettingsKeys.KEEP_NRDB_CREDENTIALS] boolValue];
        
        [[NRDB sharedInstance] stopAuthorizationRefresh];
        
        if (keep) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_NRDB]) {
                [[NRDB sharedInstance] stopAuthorizationRefresh];
                [self nrdbLogin];
            }
        } else {
            [NRDBHack clearCredentials];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:SettingsKeys.USE_NRDB];
        }
    }
}

- (void)nrdbLogin {
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if (!Reachability.online) {
        [self showOfflineAlert];
        [settings setObject:@NO forKey:SettingsKeys.USE_NRDB];
        return;
    }
    
    if ([settings boolForKey:SettingsKeys.KEEP_NRDB_CREDENTIALS]) {
        [[NRDBHack sharedInstance] enterNrdbCredentialsAndLogin];
        return;
    }
    
    if (Device.isIpad) {
        UIViewController* topMost = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [NRDBAuthPopupViewController showInViewController:topMost];
    } else {
        [NRDBAuthPopupViewController pushOn:self.iask.navigationController];
    }
}

- (void)jnetLogin {
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if (!Reachability.online) {
        [self showOfflineAlert];
        [settings setObject:@NO forKey:SettingsKeys.USE_JNET];
        return;
    }
    
    [[JintekiNet sharedInstance] enterCredentialsAndLogin];
}


- (void)settingsViewController:(id)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:SettingsKeys.DOWNLOAD_DATA_NOW])
    {
        if (Reachability.online)
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
        if (Reachability.online)
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
        if (Reachability.online)
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
        if (Reachability.online)
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
        UIAlertController* alert = [UIAlertController alertWithTitle:nil message:l10n(@"Clear Cache? You will need to re-download all data.")];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"No") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Yes") handler:^(UIAlertAction * action) {
            [[ImageCache sharedInstance] clearCache];
            [CardManager removeFiles];
            [PackManager removeFiles];
            [PrebuiltManager removeFiles];
            [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:SettingsKeys.LAST_DOWNLOAD];
            [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:SettingsKeys.NEXT_DOWNLOAD];
            [self refresh];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.LOAD_CARDS object:self];
        }]];
        
        [self.iask presentViewController:alert animated:NO completion:nil];
    }
    else if ([specifier.key isEqualToString:SettingsKeys.TEST_API])
    {
        if (Reachability.online)
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
        [UIAlertController alertWithTitle:nil message:l10n(@"Please enter a Server Name") button:l10n(@"OK")];
        return;
    }

    [SVProgressHUD showWithStatus:l10n(@"Testing...")];

    NSString* nrdbUrl = [NSString stringWithFormat:@"https://%@/api/2.0/public/card/01001", nrdbHost];
    
    [DataDownload checkNrdbApi:nrdbUrl completion:^(BOOL ok) {
        [self finishApiTests:ok];
    }];
}

-(void) finishApiTests:(BOOL)nrdbOk
{
    [SVProgressHUD dismiss];
    
    NSString* message = nrdbOk ? l10n(@"NetrunnerDB is OK") : l10n(@"NetrunnerDB is invalid");
    [UIAlertController alertWithTitle:nil message:message button:l10n(@"OK")];
}

-(void) showOfflineAlert
{
    [UIAlertController alertWithTitle:nil
                         message:l10n(@"An Internet connection is required.")
                         button:l10n(@"OK")];
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
}

@end
