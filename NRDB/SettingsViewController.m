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

-(void) refresh
{
    NSMutableSet* hiddenKeys = [NSMutableSet set];
    if (![CardData cardsAvailable])
    {
        [hiddenKeys addObjectsFromArray:@[ CARD_SETS, SET_SELECTION ]];
    }
    
    [hiddenKeys addObject:USE_EVERNOTE];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USE_DROPBOX])
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
    }
    else if ([specifier.key isEqualToString:DOWNLOAD_IMG_NOW])
    {
        TF_CHECKPOINT(@"download images");
        if ([AFNetworkReachabilityManager sharedManager].reachable)
        {
            [DataDownload downloadAllImages];
        }
    }
    else if ([specifier.key isEqualToString:CLEAR_CACHE])
    {
        TF_CHECKPOINT(@"clear cache");
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:Nil
                                                        message:l10n(@"Clear Cache? You will need to re-download all data from netrunnerdb.com.")
                                                       delegate:self
                                              cancelButtonTitle:l10n(@"No")
                                              otherButtonTitles:l10n(@"Yes"), nil];
        [alert show];
    }
}

-(void) alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [[ImageCache sharedInstance] clearCache];
        [CardData removeFile];
        [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:LAST_DOWNLOAD];
        [[NSUserDefaults standardUserDefaults] setObject:l10n(@"never") forKey:NEXT_DOWNLOAD];
        [self refresh];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self];
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
}

@end
