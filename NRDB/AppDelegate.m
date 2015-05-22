//
//  AppDelegate.m
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import <SVProgressHUD.h>
#import <AFNetworking.h>
#import <SDCAlertView.h>

#import "AppDelegate.h"
#import "CardManager.h"
#import "CardSets.h"
#import "SettingsKeys.h"
#import "DeckImport.h"
#import "CardImageViewPopover.h"
#import "NRDBAuthPopupViewController.h"
#import "NRDB.h"

#warning TODO: add card name aliases (rdi, hqi, smc, david, franklin=crick)

const NSString* const kANY = @"Any";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [self setBuiltinUserDefaults];
    
    [CardSets setupFromFiles];
    [CardManager setupFromFiles];
    
    [self setAdditionalUserDefaults];
    
    @try
    {
        DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"4mhw6piwd9wqti3" secret:@"5j8qxt2ywsrlk73"];
        [DBAccountManager setSharedManager:accountManager];
        
        DBAccount* account = [DBAccountManager sharedManager].linkedAccount;
        if (account)
        {
            DBFilesystem* fileSystem = [[DBFilesystem alloc] initWithAccount:account];
            [DBFilesystem setSharedFilesystem:fileSystem];
        }
    }
    @catch (DBException* dbEx)
    {
    }
    
    [SVProgressHUD setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
        
#if !DEBUG
    [Crashlytics startWithAPIKey:@"fe0f0f5f919be6211c1de668d91332e311ddad9e" delegate:self];
#endif
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    
    [DeckImport checkClipboardForDeck];
    [CardImageViewPopover monitorKeyboard];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status)
        {
            case AFNetworkReachabilityStatusNotReachable:
            case AFNetworkReachabilityStatusUnknown:
                [[NRDB sharedInstance] stopRefresh];
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
            case AFNetworkReachabilityStatusReachableViaWWAN:
                [[NRDB sharedInstance] refreshAuthentication];
                break;
        }
    }];
    
    return YES;
}

-(void) setBuiltinUserDefaults
{
    NSDictionary* dict = @{
        LAST_DOWNLOAD: l10n(@"never"),
        NEXT_DOWNLOAD: l10n(@"never"),
        
        USE_DRAFT_IDS: @(YES),
        USE_UNPUBLISHED_IDS: @(NO),
        AUTO_SAVE: @(NO),
        AUTO_HISTORY: @(YES),
        USE_DROPBOX: @(NO),
        AUTO_SAVE_DB: @(NO),
        USE_NRDB: @(NO),
        NRDB_AUTOSAVE: @(NO),
        NRDB_HOST: @"netrunnerdb.com",
        LANGUAGE: @"en",
        
        DECK_FILTER_STATE: @(NRDeckStateNone),
        DECK_VIEW_STYLE: @(NRCardViewLargeTable),
        DECK_VIEW_SCALE: @(1.0),
        DECK_VIEW_SORT: @(NRDeckSortType),
        DECK_FILTER_SORT: @(NRDeckListSortA_Z),
        DECK_FILTER_TYPE: @(NRFilterAll),
        
        
        BROWSER_VIEW_STYLE: @(NRCardViewLargeTable),
        BROWSER_VIEW_SCALE: @(1.0),
        BROWSER_SORT_TYPE: @(NRBrowserSortType),
        
        NUM_CORES: @(3),
        
        SHOW_ALL_FILTERS: @(YES),
        IDENTITY_TABLE: @(YES),
    };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

-(void) setAdditionalUserDefaults
{
    NSDictionary* dict = [CardSets settingsDefaults];
    if (dict.count > 0)
    {
        [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NRDB sharedInstance] stopRefresh];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [DeckImport checkClipboardForDeck];
    [[NRDB sharedInstance] refreshAuthentication];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString* scheme = [url scheme];
    
    if ([scheme isEqualToString:@"netdeck"])
    {
        [NRDBAuthPopupViewController handleOpenURL:url];
        return YES;
    }
    else if ([scheme hasPrefix:@"db-"])
    {
        @try {
            DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
            if (account)
            {
                [SVProgressHUD showSuccessWithStatus:l10n(@"Successfully connected to your Dropbox account")];

                DBFilesystem* fileSystem = [[DBFilesystem alloc] initWithAccount:account];
                [DBFilesystem setSharedFilesystem:fileSystem];
            }
            [[NSUserDefaults standardUserDefaults] setBool:(account != nil) forKey:USE_DROPBOX];
        }
        @catch (DBException* dbEx)
        {}
        
        return YES;
    }
    
	return NO;
}

+(NSString*) appVersion
{
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    // CFBundleShortVersionString contains the main version
    NSString* version = [@"v" stringByAppendingString:[bundleInfo objectForKey:@"CFBundleShortVersionString"]];
    
#if defined(DEBUG) || defined(ADHOC)
    // CFBundleVersion contains the git rev-parse output
    version = [NSString stringWithFormat:@"%@-%@", version, [bundleInfo objectForKey:@"CFBundleVersion"]];
#endif
    
    return version;
}

#pragma mark - crashlytics delegate

@class CLSReport;
- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport *)report completionHandler:(void (^)(BOOL submit))completionHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completionHandler)
        {
            completionHandler(YES);
        }
    });
    
    SDCAlertView* alert = [SDCAlertView alertWithTitle:l10n(@"Oops, we crashed :(")
                                               message:l10n(@"Sorry, that shouldn't have happened.\nIf you can reproduce the bug, please tell the developers about it.")
                                               buttons:@[l10n(@"Not now"), l10n(@"OK")]];
    
    alert.didDismissHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1)
        {
            NSString* url = [NSString stringWithFormat:@"mailto:netdeck@steffens.org?subject=Bug in Net Deck %@", [AppDelegate appVersion]];
            url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
    };
}

@end
