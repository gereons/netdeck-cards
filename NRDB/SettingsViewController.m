//
//  SettingsViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 27.03.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <SVProgressHUD.h>
#import <Dropbox/Dropbox.h>

#import "SettingsViewController.h"

#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "CardData.h"
#import "Card.h"
#import "ImageCache.h"
#import "SettingsKeys.h"
#import "Notifications.h"

@interface SettingsViewController ()

@property IASKAppSettingsViewController* iask;
@property BOOL imageDownloadOK;

@property NSArray* cards;
@property NSInteger index;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.iask = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.iask.showDoneButton = NO;
    self.iask.delegate = self;
    
    self.navigationController.navigationBar.topItem.title = @"Settings";
    [self.navigationController setViewControllers:@[ self.iask ]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:kIASKAppSettingChanged object:nil];
    
    [self refresh];
}

-(void) refresh
{
    NSMutableSet* hiddenKeys = [NSMutableSet set];
    if (![CardData cardsAvailable])
    {
        [hiddenKeys  addObjectsFromArray:@[ CARD_SETS, SET_SELECTION ]];
    }
    
    [hiddenKeys addObject:USE_EVERNOTE];
    
    [self.iask setHiddenKeys:hiddenKeys];
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
    }
}

- (void)settingsViewController:(id)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:DOWNLOAD_DATA_NOW])
    {
        TF_CHECKPOINT(@"download data");
        [self downloadData];
    }
    else if ([specifier.key isEqualToString:DOWNLOAD_IMG_NOW])
    {
        TF_CHECKPOINT(@"download images");
        [self downloadAllImages];
    }
    else if ([specifier.key isEqualToString:CLEAR_CACHE])
    {
        TF_CHECKPOINT(@"clear cache");
        
        [[ImageCache sharedInstance] clearCache];
        [CardData removeFile];
        [[NSUserDefaults standardUserDefaults] setObject:@"never" forKey:LAST_DOWNLOAD];
        [[NSUserDefaults standardUserDefaults] setObject:@"never" forKey:NEXT_DOWNLOAD];
        [self refresh];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self];
    }
}

-(void) downloadData
{
    [SVProgressHUD showWithStatus:@"Loading Card Data" maskType:SVProgressHUDMaskTypeBlack];
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL ok = [CardData setupFromNetrunnerDbApi];
        [SVProgressHUD dismiss];
        
        if (ok)
        {
            [self refresh];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to download cards at this time. Please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
        }
    });
}

-(void) downloadAllImages
{
    [SVProgressHUD showProgress:0 status:@"Downloading Card Images" maskType:SVProgressHUDMaskTypeBlack];
    
    self.imageDownloadOK = YES;

    self.cards = [Card allCards];

    [self downloadImageForCard:@(0)];
}

-(void) downloadImageForCard:(NSNumber*)index
{
    if (!self.imageDownloadOK)
    {
        [SVProgressHUD dismiss];
        self.cards = nil;
        return;
    }
    
    int i = [index intValue];
    if (i < self.cards.count)
    {
        Card* card = [self.cards objectAtIndex:i];
        [[ImageCache sharedInstance] getImageFor:card success:^(Card* card, UIImage* image) {
            float progress = (i+1) * 100.0 / self.cards.count;
            // NSLog(@"progress %f", progress);
            [SVProgressHUD showProgress:progress/100.0 status:@"Downloading Card Images" maskType:SVProgressHUDMaskTypeBlack];
            
            // use -performSelector: so the hud can refresh
            [self performSelector:@selector(downloadImageForCard:) withObject:@(i+1) afterDelay:.005];
        }
        failure:^(Card* card, NSInteger statusCode) {
            if (statusCode >= 400)
            {
                self.imageDownloadOK = NO;
            }
        }];
    }
    else
    {
        [SVProgressHUD dismiss];
        self.cards = nil;
    }
}


- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
}

@end
