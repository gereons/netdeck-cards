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
#import <AFNetworking.h>

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
            UIViewController* topMost = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
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
