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

#import "NRSwitch.h"
#import "SettingsViewController.h"
#import "CardSets.h"
#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "DataDownload.h"
#import "CardManager.h"
#import "ImageCache.h"
#import "SettingsKeys.h"
#import "Notifications.h"
#import "NRDBAuthPopupViewController.h"

@interface SettingsViewController ()

@property IASKAppSettingsViewController* iask;

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
    [CardSets clearDisabledSets];
    
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
        TF_CHECKPOINT(@"api settings test");
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

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier
{
    return 44;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"toggleCell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"toggleCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NRSwitch* setSwitch = [[NRSwitch alloc] initWithHandler:^(BOOL on) {
        [CardSets clearDisabledSets];
        [[NSUserDefaults standardUserDefaults] setBool:on forKey:specifier.key];
    }];
    
    setSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:specifier.key];
    cell.accessoryView = setSwitch;
    cell.textLabel.textColor = [UIColor blackColor];
    NSString* setName = [CardSets nameForKey:specifier.key];
    if (setName)
    {
        cell.textLabel.text = setName;
    }
    else
    {
        // setName = l10n(@"-Unreleased-");
        cell.textLabel.text = specifier.title;
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

-(void) testApiSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSString* nrdbHost = [settings objectForKey:NRDB_HOST];
    NSString* cardsUrl = [settings objectForKey:CARDS_ENDPOINT];
    NSString* lockpickCode = [settings objectForKey:LOCKPICK_CODE];
    
    if (nrdbHost.length == 0 && cardsUrl.length == 0 && lockpickCode.length == 0)
    {
        [SDCAlertView alertWithTitle:nil message:l10n(@"Please enter a Server Name, Cards Endpoint URL, and/or a Lockpick code") buttons:@[l10n(@"OK")]];
        return;
    }

    [SVProgressHUD showWithStatus:l10n(@"Testing...")];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    if (nrdbHost.length)
    {
        NSString* nrdbUrl = [NSString stringWithFormat:@"http://%@/api/cards/", nrdbHost];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:nrdbUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            
            [self testDatasucker:@{ @"nrdb": @(ok) }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self testDatasucker:@{ @"nrdb": @NO }];
        }];
    }
    else
    {
        [self testDatasucker:@{}];
    }
}

-(void) testDatasucker:(NSDictionary*)previousResults;
{
    NSMutableDictionary* results = previousResults.mutableCopy;
    
    NSString* cardsUrl = [[NSUserDefaults standardUserDefaults] objectForKey:CARDS_ENDPOINT];
    if (cardsUrl.length)
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:cardsUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            
            results[@"datasucker"] = @(ok);
            [self testLockpick:results];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            results[@"datasucker"] = @NO;
            [self testLockpick:results];
        }];
    }
    else
    {
        [self testLockpick:results];
    }
}

-(void) testLockpick:(NSMutableDictionary*)results
{
    NSString* lockpickCode = [[NSUserDefaults standardUserDefaults] objectForKey:LOCKPICK_CODE];

    if (lockpickCode.length)
    {
        NSString* code = [lockpickCode stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        NSString* lockpickUrl =[NSString stringWithFormat:@"https://lockpick.parseapp.com/datasucker/%@", code];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:lockpickUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            BOOL ok = YES;
            if ([responseObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* dict = responseObject;
                if (dict[@"url"] == nil)
                {
                    ok = NO;
                }
            }
            
            results[@"lockpick"] = @(ok);
            [self finishApiTests:results];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            results[@"lockpick"] = @NO;
            [self finishApiTests:results];
        }];
    }
    else
    {
        [self finishApiTests:results];
    }
}

-(void) finishApiTests:(NSDictionary*)results
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    NSNumber* nrdbOk = results[@"nrdb"];
    NSNumber* cardsOk = results[@"datasucker"];
    NSNumber* lockpickOk = results[@"lockpick"];
    
    NSString* nrdbMsg;
    if (nrdbOk)
    {
        nrdbMsg = nrdbOk.intValue ? l10n(@"NetrunnerDB is OK") : l10n(@"NetrunnerDB is invalid");
    }
    else
    {
        nrdbMsg = l10n(@"NetrunnerDB not tested");
    }
    
    NSString* cardsMsg;
    if (cardsOk)
    {
        cardsMsg = cardsOk.intValue ? l10n(@"Cards Endpoint URL is OK") : l10n(@"Cards Endpoint URL is invalid");
    }
    else
    {
        cardsMsg = l10n(@"Cards Endpoint URL not tested");
    }
    
    NSString* lockpickMsg;
    if (lockpickOk)
    {
        lockpickMsg = lockpickOk.intValue ? l10n(@"Lockpick code is OK") : l10n(@"Lockpick code is invalid");
    }
    else
    {
        lockpickMsg = l10n(@"Lockpick code not tested");
    }
    
    NSString* message = [NSString stringWithFormat:@"%@\n%@\n%@", nrdbMsg, cardsMsg, lockpickMsg];
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
