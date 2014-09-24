//
//  SettingsViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 27.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SVProgressHUD.h>
#import <Dropbox/Dropbox.h>
#import <SDCAlertView.h>
#import <EXTScope.h>
#import <PromiseKit.h>

#import "SettingsViewController.h"

#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "DataDownload.h"
#import "CardManager.h"
#import "ImageCache.h"
#import "SettingsKeys.h"
#import "Notifications.h"
#if _NRDB_
#import "NRDBAuthPopupViewController.h"
#endif

#warning setselection - use names from card sets!

@interface SettingsViewController ()

@property IASKAppSettingsViewController* iask;

@property NSInteger index;

@end

@implementation SettingsViewController

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.iask = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.iask.showDoneButton = NO;
    self.iask.delegate = self;
    
    self.navigationController.navigationBar.topItem.title = l10n(@"Settings");
    [self.navigationController setViewControllers:@[ self.iask ]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:kIASKAppSettingChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardsLoaded:) name:LOAD_CARDS object:nil];
    
    
    [self refresh];
}

-(void) refresh
{
    NSMutableSet* hiddenKeys = [NSMutableSet set];
    if (![CardManager cardsAvailable])
    {
        [hiddenKeys addObjectsFromArray:@[ @"sets_hide_1", @"sets_hide_2" ]];
    }
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if (![settings boolForKey:USE_DROPBOX])
    {
        [hiddenKeys addObject:AUTO_SAVE_DB];
    }
#if !_NRDB_
    [hiddenKeys addObjectsFromArray:@[ @"nrdb_hide_1", @"nrdb_hide_2" ]];
#endif
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
    if ([notification.object isEqualToString:USE_DROPBOX])
    {
        BOOL useDropbox = [[notification.userInfo objectForKey:USE_DROPBOX] boolValue];
        
        DBAccountManager* accountManager = [DBAccountManager sharedManager];
        DBAccount *account = accountManager.linkedAccount;
        
        if (useDropbox)
        {
            if (!account)
            {
                TF_CHECKPOINT(@"link dropbox");
                UIViewController* topMost = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
                [accountManager linkFromController:topMost];
            }
        }
        else
        {
            if (account)
            {
                TF_CHECKPOINT(@"unlink dropbox");
                [account unlink];
                [DBFilesystem setSharedFilesystem:nil];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DROPBOX_CHANGED object:self];
        [self refresh];
    }
#if _NRDB_
    else if ([notification.object isEqualToString:USE_NRDB])
    {
        BOOL useNrdb = [[notification.userInfo objectForKey:USE_NRDB] boolValue];
        
        if (useNrdb)
        {
            UIViewController* topMost = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
            TF_CHECKPOINT(@"netrunnerdb.com login");
            if (APP_ONLINE)
            {
                [NRDBAuthPopupViewController showInViewController:topMost];
            }
            else
            {
                [self showOfflineAlert];
                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:USE_NRDB];
            }
        }
        else
        {
            TF_CHECKPOINT(@"netrunnerdb.com logout");
            NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
            [settings removeObjectForKey:NRDB_ACCESS_TOKEN];
            [settings removeObjectForKey:NRDB_REFRESH_TOKEN];
            [settings removeObjectForKey:NRDB_TOKEN_EXPIRY];
            [settings removeObjectForKey:NRDB_TOKEN_TTL];
        }
    }
#endif
}

- (void)settingsViewController:(id)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:DOWNLOAD_DATA_NOW])
    {
        TF_CHECKPOINT(@"download data");
        if (APP_ONLINE)
        {
            [DataDownload downloadCardData];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
    else if ([specifier.key isEqualToString:DOWNLOAD_IMG_NOW])
    {
        TF_CHECKPOINT(@"download images");
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
        TF_CHECKPOINT(@"download missing images");
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
        TF_CHECKPOINT(@"clear cache");
        
        SDCAlertView* alert = [SDCAlertView alertWithTitle:nil
                                                   message:l10n(@"Clear Cache? You will need to re-download all data.")
                                                   buttons:@[l10n(@"No"), l10n(@"Yes") ]];
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 1) // yes, clear
            {
                [[ImageCache sharedInstance] clearCache];
                [CardManager removeFiles];
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:LAST_DOWNLOAD];
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:NEXT_DOWNLOAD];
                [self refresh];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self];
            }
        };
    }
    else if ([specifier.key isEqualToString:TEST_DATASUCKER])
    {
        TF_CHECKPOINT(@"datasucker test");
        if (APP_ONLINE)
        {
            [self testDatasucker];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
}

-(void) testDatasucker
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* lockpick = [settings objectForKey:LOCKPICK_CODE];
    NSString* cardsUrl = [settings objectForKey:CARDS_ENDPOINT];
    
    BOOL ok = lockpick.length || cardsUrl.length;
    if (!ok)
    {
        [SDCAlertView alertWithTitle:nil message:@"Please enter either a lockpick code or an endpoint URL" buttons:@[@"OK"]];
        return;
    }

    [SVProgressHUD showWithStatus:l10n(@"Testing...")];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString* __block lockpickResult, * __block cardsResult;
    NSInteger __block lockpickIndex = -1, cardsIndex = -1;
    NSInteger index = 0;
    NSMutableArray* promises = [NSMutableArray array];
    
    PMKPromise* promise;
    if (lockpick.length)
    {
        NSString* lockpickUrl = [NSString stringWithFormat:@"https://lockpick.parseapp.com/datasucker/%@", lockpick ];
        promise = [NSURLConnection GET:lockpickUrl];
        promise.catch(^(NSError *error) {
            lockpickResult = @"Lockpick: Fail";
        });
        [promises addObject:promise];
        lockpickIndex = index++;
    }
    else
    {
        lockpickResult = @"Lockpick: not tested.";
    }
    
    if (cardsUrl.length)
    {
        PMKPromise *promise = [NSURLConnection GET:cardsUrl];
        promise.catch(^(NSError *error) {
            cardsResult = @"Cards: Fail";
        });
        [promises addObject:promise];
        cardsIndex = index++;
    }
    else
    {
        cardsResult = @"Cards: not tested";
    }
    
    [PMKPromise when:promises].then(^(NSArray *results) {
        // NSLog(@"%d results", results.count);
        if (lockpickIndex != -1)
        {
            NSDictionary* dict = results[lockpickIndex];
            if (dict)
            {
                lockpickResult = @"Lockpick: OK";
            }
            else
            {
                lockpickResult = @"Lockpick: Fail";
            }
        }
        if (cardsIndex != -1)
        {
            NSDictionary* data = results[cardsIndex];
            cardsResult = data ? @"Cards: OK" : @"Cards: Fail";
        }

    }).finally(^{
        NSMutableString *message = [NSMutableString stringWithString:lockpickResult ? lockpickResult : @"Lockpick: not tested"];
        [message appendString:@"\n"];
        [message appendString:cardsResult ? cardsResult : @"Cards: not tested"];
        
        [self finishDatasuckerTests:message];
    });
}

-(void) finishDatasuckerTests:(NSString*)message
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
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
