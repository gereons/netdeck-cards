//
//  AppDelegate.m
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import <SVProgressHUD.h>
#import <Crashlytics/Crashlytics.h>

#import "AppDelegate.h"
#import "CardManager.h"
#import "SettingsKeys.h"
#import "CardSets.h"
#import "DeckImport.h"
#import "Card.h"
#import "CardImageViewPopover.h"
#import "NRDBAuthPopupViewController.h"
#import "NRDB.h"

const NSString* const kANY = @"Any";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setUserDefaults];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [CardManager setupFromFiles];
    
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"4mhw6piwd9wqti3" secret:@"5j8qxt2ywsrlk73"];
	[DBAccountManager setSharedManager:accountManager];
    
    DBAccount* account = [DBAccountManager sharedManager].linkedAccount;
    if (account)
    {
        DBFilesystem* fileSystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:fileSystem];
    }
    
    [SVProgressHUD setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
    
#if ADHOC && !TARGET_IPHONE_SIMULATOR
    [TestFlight takeOff:@"eb5e8194-c06f-46db-a1ce-42943ebaf902"];
#endif
    
#if !DEBUG
    [Crashlytics startWithAPIKey:@"fe0f0f5f919be6211c1de668d91332e311ddad9e"];
#endif
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    
    [DeckImport checkClipboardForDeck];
    [CardImageViewPopover monitorKeyboard];
    
    [self removeOldNrdbData];
    
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

-(void) setUserDefaults
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:[CardSets settingsDefaults]];
    
    [dict addEntriesFromDictionary:@{
        LAST_DOWNLOAD: l10n(@"never"),
        NEXT_DOWNLOAD: l10n(@"never"),
        
        IGNORE_UNKNOWN_SETS: @(YES),
        USE_DRAFT_IDS: @(YES),
        USE_UNPUBLISHED_IDS: @(NO),
        AUTO_SAVE: @(NO),
        USE_DROPBOX: @(NO),
        AUTO_SAVE_DB: @(NO),
        USE_NRDB: @(NO),
        NRDB_AUTOSAVE: @(NO),
        NRDB_HOST: @"netrunnerdb.com",
        
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
    }];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];    
}

-(void) removeOldNrdbData
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if ([settings boolForKey:@"_nrdb_removed_"])
    {
        return;
    }
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    NSString* images = [documentsDirectory stringByAppendingPathComponent:@"images"];
    
    NSFileManager* mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:images error:nil];
    
    NSString* json = [documentsDirectory stringByAppendingPathComponent:@"nrcards_en.json"];
    [mgr removeItemAtPath:json error:nil];
    
    [settings setBool:YES forKey:@"_nrdb_removed_"];
    [settings synchronize];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

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
    }
    else
    {
        DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
        if (account)
        {
            [SVProgressHUD showSuccessWithStatus:l10n(@"Successfully connected to your Dropbox account")];
            
            TF_CHECKPOINT(@"dropbox linked");
            DBFilesystem* fileSystem = [[DBFilesystem alloc] initWithAccount:account];
            [DBFilesystem setSharedFilesystem:fileSystem];
        }
        [[NSUserDefaults standardUserDefaults] setBool:(account != nil) forKey:USE_DROPBOX];
    }
    
	return YES;
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
@end
