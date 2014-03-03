//
//  AppDelegate.m
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <TMCache.h>
#import <AFNetworking.h>
#import <Dropbox/Dropbox.h>
#import <SVProgressHUD.h>

#import "AppDelegate.h"
#import "CardData.h"
#import "SettingsKeys.h"
#import "CardSets.h"
#import "DeckImport.h"
#import "Notifications.h"

@interface  AppDelegate()
@property Deck* deck;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [AppDelegate setUserDefaults];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [CardData setupFromFile];
    
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"4mhw6piwd9wqti3" secret:@"5j8qxt2ywsrlk73"];
	[DBAccountManager setSharedManager:accountManager];
    
    DBAccount* account = [DBAccountManager sharedManager].linkedAccount;
    if (account)
    {
        DBFilesystem* fileSystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:fileSystem];
    }
    
    SVProgressHUD.appearance.hudBackgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    
#if !DEBUG && !TARGET_IPHONE_SIMULATOR
    [TestFlight takeOff:@"eb5e8194-c06f-46db-a1ce-42943ebaf902"];
#endif
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    
    // setup tmcache: 50mb space
    [TMCache sharedCache].diskCache.byteLimit = 50 * 1024 * 1024;
    
    [self checkClipboardForDeck];
    
    return YES;
}

+(void) setUserDefaults
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:[CardSets settingsDefaults]];
    
    [dict addEntriesFromDictionary:@{
        LAST_DOWNLOAD: l10n(@"never"),
        NEXT_DOWNLOAD: l10n(@"never"),
        USE_DROPBOX: @(NO),
        USE_EVERNOTE: @(NO),
        AUTO_SAVE: @(NO),
        AUTO_SAVE_DB: @(NO),
        DECK_VIEW_STYLE: @(1),
        LANGUAGE: @"en"
    }];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self checkClipboardForDeck];
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
	DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
	if (account)
    {
        [SVProgressHUD showSuccessWithStatus:l10n(@"Successfully connected to your Dropbox account")];
        
        TF_CHECKPOINT(@"dropbox linked");
        DBFilesystem* fileSystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:fileSystem];
	}
    [[NSUserDefaults standardUserDefaults] setBool:(account != nil) forKey:USE_DROPBOX];
	
	return YES;
}

-(void) checkClipboardForDeck
{
    self.deck = [DeckImport parseClipboard];
    
    if (self.deck != nil)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:l10n(@"Detected a deck list in your clipboard. Import this deck?") delegate:self cancelButtonTitle:l10n(@"No") otherButtonTitles:l10n(@"Yes"), nil];
        [alert show];
    }
}

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:IMPORT_DECK object:self userInfo:@{ @"deck": self.deck }];
        self.deck = nil;
    }
}

@end
