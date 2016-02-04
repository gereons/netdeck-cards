//
//  AppDelegate.m
//  Net Deck
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

// TODOs:
// card/set update in bg fetch?

#warning 3d touch shortcuts
#warning improve startup time!
#warning remove grmustache?
#warning iphone browser: add hint on startup, more filters (type + set)
#warning remove SDCalertview where not needed

@import SVProgressHUD;
@import AFNetworking;

#import <Dropbox/Dropbox.h>
#import "AppDelegate.h"
#import "DeckImport.h"
#import "CardImageViewPopover.h"
#import "NRDBAuthPopupViewController.h"
#import "NRDBAuth.h"
#import "NRDB.h"

const NSString* const kANY = @"Any";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if USE_CRASHLYTICS
    [CrashlyticsKit setDelegate:self];
    [Fabric with:@[ CrashlyticsKit ]];
#endif
    
    [self moveFilesFromCacheToAppSupportDirectory];
    
    [self setBuiltinUserDefaults];
    
    BOOL setsOk = NO, cardsOk = NO;
    
    setsOk = [CardSets setupFromFiles];
    if (setsOk) {
        cardsOk = [CardManager setupFromFiles];
    }
    
    if (!setsOk || !cardsOk) {
        [CardSets removeFiles];
        [CardManager removeFiles];
    }
    
    BOOL useNrdb = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_NRDB];
    NSTimeInterval fetchInterval = useNrdb ? BG_FETCH_INTERVAL : UIApplicationBackgroundFetchIntervalNever;
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:fetchInterval];
    
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
    @catch (DBException* dbEx) {}
    
    [SVProgressHUD setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
    
    [DeckImport checkClipboardForDeck];
    [CardImageViewPopover monitorKeyboard];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
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
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if (IS_IPHONE)
    {
        self.window.rootViewController = self.navigationController;
    }
    else
    {
        self.window.rootViewController = self.splitViewController;
    }
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(void) setBuiltinUserDefaults
{
    NSDictionary* dict = @{
        SettingsKeys.LAST_DOWNLOAD: l10n(@"never"),
        SettingsKeys.NEXT_DOWNLOAD: l10n(@"never"),
        
        SettingsKeys.USE_DRAFT_IDS: @(YES),
        SettingsKeys.AUTO_SAVE: @(NO),
        SettingsKeys.AUTO_HISTORY: @(YES),
        SettingsKeys.USE_DROPBOX: @(NO),
        SettingsKeys.AUTO_SAVE_DB: @(NO),
        SettingsKeys.USE_NRDB: @(NO),
        SettingsKeys.NRDB_AUTOSAVE: @(NO),
        SettingsKeys.NRDB_HOST: @"netrunnerdb.com",
        SettingsKeys.LANGUAGE: @"en",
        SettingsKeys.UPDATE_INTERVAL: @(7),
        SettingsKeys.LAST_BG_FETCH: l10n(@"never"),
        
        SettingsKeys.DECK_FILTER_STATE: @(NRDeckStateNone),
        SettingsKeys.DECK_VIEW_STYLE: @(NRCardViewLargeTable),
        SettingsKeys.DECK_VIEW_SCALE: @(1.0),
        SettingsKeys.DECK_VIEW_SORT: @(NRDeckSortType),
        SettingsKeys.DECK_FILTER_SORT: @(NRDeckListSortA_Z),
        SettingsKeys.DECK_FILTER_TYPE: @(NRFilterAll),
        
        SettingsKeys.CREATE_DECK_ACTIVE: @(NO),
        
        SettingsKeys.BROWSER_VIEW_STYLE: @(NRCardViewLargeTable),
        SettingsKeys.BROWSER_VIEW_SCALE: @(1.0),
        SettingsKeys.BROWSER_SORT_TYPE: @(NRBrowserSortType),
        
        SettingsKeys.NUM_CORES: @(3),
        
        SettingsKeys.SHOW_ALL_FILTERS: @(YES),
        SettingsKeys.IDENTITY_TABLE: @(YES),
        
        SettingsKeys.USE_NAPD_MWL: @(YES),
    };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NRDB sharedInstance] stopRefresh];
}

-(void) moveFilesFromCacheToAppSupportDirectory
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if ([settings boolForKey:SettingsKeys.FILES_MOVED]) {
        return;
    }
    
    NSString* cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString* supportDir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSArray* files = @[ CARDS_FILENAME, CARDS_FILENAME_EN, SETS_FILENAME, IMAGES_DIRNAME ];
    for (NSString* file in files) {
        NSString* cachePath = [cacheDir stringByAppendingPathComponent:file];
        BOOL isDirectory;
        if ([fileMgr fileExistsAtPath:cachePath isDirectory:&isDirectory]) {
            NSString* supportPath = [supportDir stringByAppendingPathComponent:file];
            NSError* error = nil;
            BOOL ok = [fileMgr moveItemAtPath:cachePath toPath:supportPath error:&error];
            if (!ok || error) {
                NSLog(@"move error=%@", error);
            }
            
            if (!isDirectory) {
                [AppDelegate excludeFromBackup:supportPath];
            }
        }
    }
    
    NSString* imagesDir = [supportDir stringByAppendingPathComponent:IMAGES_DIRNAME];
    files = [fileMgr contentsOfDirectoryAtPath:imagesDir error:nil];
    for (NSString* file in files) {
        NSString* pathname = [imagesDir stringByAppendingPathComponent:file];
        [AppDelegate excludeFromBackup:pathname];
    }

    [settings setBool:YES forKey:SettingsKeys.FILES_MOVED];
}

+(void) excludeFromBackup:(NSString*)path
{
    NSURL* url = [NSURL fileURLWithPath:path];
    NSError* error = nil;
    BOOL ok = [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (!ok || error) {
        NSLog(@"setResource error=%@", error);
    }
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


- (void) application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    // Called when the user selects a shortcut item on the home screen (iPhone 6s/6s+)
    completionHandler(NO);
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString* scheme = [url scheme];
    
    if ([scheme isEqualToString:@"netdeck"])
    {
        if ([url.host isEqualToString:@"oauth2"])
        {
            [NRDBAuthPopupViewController handleOpenURL:url];
        }
        if ([url.host isEqualToString:@"load"])
        {
            [DeckImport importDeckFromLocalUrl:url];
        }
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
            [[NSUserDefaults standardUserDefaults] setBool:(account != nil) forKey:SettingsKeys.USE_DROPBOX];
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

#pragma mark - background fetch

// protect against running two bg fetches simultaneously - happens when initiated from Xcode manually
static BOOL runningBackgroundFetch = NO;

-(void) application:(UIApplication *)application performFetchWithCompletionHandler:(BackgroundFetchCompletionBlock)completionHandler
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:SettingsKeys.LAST_BG_FETCH];
    
    if (runningBackgroundFetch)
    {
        // NSLog(@"dup call");
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    runningBackgroundFetch = YES;
    [[NRDB sharedInstance] backgroundRefreshAuthentication:^(UIBackgroundFetchResult result) {
        // NSLog(@"primary call %ld", (long)result);
        completionHandler(result);
        runningBackgroundFetch = NO;
    }];
}

+(BOOL) online {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

#pragma mark - crashlytics delegate

#if USE_CRASHLYTICS
- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport *)report completionHandler:(void (^)(BOOL submit))completionHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completionHandler)
        {
            completionHandler(YES);
        }
    });
    
    [self performSelector:@selector(showCrashAlert) withObject:nil afterDelay:0.15];
}

-(void) showCrashAlert {
    NSString* msg = l10n(@"Sorry, that shouldn't have happened.\nIf you can reproduce the bug, please tell the developers about it.");
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Oops, we crashed :(")
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Not now") handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction *action) {
        NSString* subject = [NSString stringWithFormat:@"Bug in Net Deck %@", [AppDelegate appVersion]];
        NSString* body = @"If possible, please describe what caused the crash. Thanks!";
        
        NSMutableString* mailto = @"mailto:netdeck@steffens.org?subject=".mutableCopy;
        [mailto appendString:[subject stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
        [mailto appendString:@"&body="];
        [mailto appendString:[body stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailto]];
    }]];
    
    [self.window.rootViewController presentViewController:alert animated:NO completion:nil];
}
#endif

@end
