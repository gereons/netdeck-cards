//
//  SettingsViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 27.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SVProgressHUD.h>
#import <Dropbox/Dropbox.h>
#import <AFNetworking.h>
#import <SDCAlertView.h>
#import <AFNetworking.h>
#import <EXTScope.h>

#import "SettingsViewController.h"

#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "DataDownload.h"
#import "CardData.h"
#import "ImageCache.h"
#import "SettingsKeys.h"
#import "Notifications.h"

@interface SettingsViewController ()

@property IASKAppSettingsViewController* iask;

@property NSInteger index;

@end

@implementation SettingsViewController

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

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) refresh
{
    NSMutableSet* hiddenKeys = [NSMutableSet set];
    if (![CardData cardsAvailable])
    {
        [hiddenKeys addObjectsFromArray:@[ CARD_SETS, SET_SELECTION ]];
    }
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if (![settings objectForKey:NRDB_REMEMBERME])
    {
        [hiddenKeys addObject:NRDB_LOGOUT];
    }
    else
    {
        [hiddenKeys addObject:NRDB_LOGIN];
    }
    
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
}

- (void)settingsViewController:(id)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:DOWNLOAD_DATA_NOW])
    {
        TF_CHECKPOINT(@"download data");
        if ([AFNetworkReachabilityManager sharedManager].reachable)
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
        if ([AFNetworkReachabilityManager sharedManager].reachable)
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
        if ([AFNetworkReachabilityManager sharedManager].reachable)
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
                                                   message:l10n(@"Clear Cache? You will need to re-download all data from netrunnerdb.com.")
                                                   buttons:@[l10n(@"No"), l10n(@"Yes") ]];
        alert.didDismissHandler = ^void(NSInteger buttonIndex) {
            if (buttonIndex == 1) // yes, clear
            {
                [[ImageCache sharedInstance] clearCache];
                [CardData removeFile];
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:LAST_DOWNLOAD];
                [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:NEXT_DOWNLOAD];
                [self refresh];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self];
            }
        };
    }
    else if ([specifier.key isEqualToString:NRDB_LOGOUT])
    {
        TF_CHECKPOINT(@"netrunnerdb.com logout");
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:NRDB_REMEMBERME];
        [self refresh];
    }
    else if ([specifier.key isEqualToString:NRDB_LOGIN])
    {
        TF_CHECKPOINT(@"netrunnerdb.com login");
        if ([AFNetworkReachabilityManager sharedManager].reachable)
        {
            [self netrunnerDbLogin];
        }
        else
        {
            [self showOfflineAlert];
        }
    }
}

-(void) netrunnerDbLogin
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Logging in...")];
    
    [self performSelector:@selector(checkNetrunnerDbLogin) withObject:nil afterDelay:0.01];
}

-(void) checkNetrunnerDbLogin
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    NSString* user = [settings objectForKey:NRDB_USERNAME];
    NSString* pass = [settings objectForKey:NRDB_PASSWORD];
    
    if (user.length == 0 || pass.length == 0)
    {
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Please enter username and password for your netrunnerdb.com account")
                             buttons:@[l10n(@"OK")]];
        return;
    }
    
    // remove old REMEMBERME cookie
    NSHTTPCookieStorage* jar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie* cookie in [jar cookies])
    {
        [jar deleteCookie:cookie];
    }
    
    // fake a PHPSESSID cookie
    NSHTTPCookie* cookie = [self nrdbCookie:@"PHPSESSID" value:@"dontcare"];
    NSDictionary *cookies = [NSHTTPCookie requestHeaderFieldsWithCookies:@[ cookie ]];

    NSError* error;
    NSString* loginUrl = @"http://netrunnerdb.com/login_check";
    NSDictionary* parameters = @{
                                 @"_username": user,
                                 @"_password": pass,
                                 @"_remember_me": @"on",
                                 @"_csrf_token": @"",
                                 @"_submit": @"Login",
                                 };

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST"
                                                                                 URLString:loginUrl
                                                                                parameters:parameters
                                                                                     error:&error];
    [request setAllHTTPHeaderFields:cookies];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        NSString* rememberme;
        for (NSHTTPCookie* cookie in [jar cookies])
        {
            if ([cookie.name isEqualToString:@"REMEMBERME"])
            {
                rememberme = cookie.value;
                break;
            }
        }
        
        if (rememberme)
        {
            [settings setObject:rememberme forKey:NRDB_REMEMBERME];
            [self checkLogin];
        }
        else
        {
            [self loginFinished:NO];
        }
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self loginFinished:NO];
    }];
    [operation start];
}

-(void) checkLogin
{
    NSString* decksUrl = @"http://netrunnerdb.com/api/decks";
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSHTTPCookie* cookie = [self nrdbCookie:@"REMEMBERME" value:[settings objectForKey:NRDB_REMEMBERME]];
    NSDictionary *cookies = [NSHTTPCookie requestHeaderFieldsWithCookies:@[ cookie ]];
    
    NSError* error;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                                 URLString:decksUrl
                                                                                parameters:nil
                                                                                     error:&error];
    [request setAllHTTPHeaderFields:cookies];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        [self loginFinished:YES];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(self);
        [self loginFinished:NO];
    }];
    [operation start];
}

-(void) loginFinished:(BOOL)ok
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    if (!ok)
    {
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Login at netrunnerdb.com failed")
                             buttons:@[l10n(@"OK")]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:NRDB_REMEMBERME];
    }
    else
    {
        [self refresh];
    }
}

-(NSHTTPCookie*) nrdbCookie:(NSString*)name value:(NSString*)value
{
    NSDictionary *properties = @{
                                 NSHTTPCookiePath: @"/",
                                 NSHTTPCookieDomain: @"netrunnerdb.com",
                                 NSHTTPCookieName: name,
                                 NSHTTPCookieValue: value,
                                 };
    return [NSHTTPCookie cookieWithProperties:properties];
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
