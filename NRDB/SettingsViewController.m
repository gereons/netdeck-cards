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

@property int imageDownloadErrors;
@property BOOL imageDownloadStopped;

@property UIAlertView* alert;
@property UIProgressView* progressView;

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
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USE_DROPBOX])
    {
        [hiddenKeys addObject:AUTO_SAVE_DB];
    }
    
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
        [self refresh];
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
    [SettingsViewController downloadData:^() {
        [self refresh];

        [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_CARDS object:self];
    }];
}

+(void) downloadData:(void (^)())block
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [SVProgressHUD showWithStatus:@"Loading Card Data" maskType:SVProgressHUDMaskTypeBlack];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL ok = [CardData setupFromNetrunnerDbApi];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [SVProgressHUD dismiss];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if (ok)
            {
                if (block)
                {
                    block();
                }
            }
            else
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to download cards at this time. Please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
            }
        });
    });
}

-(void) downloadAllImages
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 250, 20)];
    
    self.alert = [[UIAlertView alloc] initWithTitle:@"Downloading Images" message:nil delegate:self cancelButtonTitle:@"Stop" otherButtonTitles:nil];
    [self.alert setValue:self.progressView forKey:@"accessoryView"];
    [self.alert show];
    
    self.imageDownloadStopped = NO;
    self.imageDownloadErrors = 0;

    self.cards = [Card allCards];

    [self downloadImageForCard:@(0)];
}

-(void) downloadImageForCard:(NSNumber*)index
{
    if (self.imageDownloadStopped)
    {
        return;
    }
    
    int i = [index intValue];
    if (i < self.cards.count)
    {
        Card* card = [self.cards objectAtIndex:i];

        [[ImageCache sharedInstance] getImageFor:card success:^(Card* card, UIImage* image) {
            float progress = (i+1) * 100.0 / self.cards.count;
            // NSLog(@"%@ - progress %.1f", card.name, progress);
            
            self.progressView.progress = progress/100.0;
            
            // use -performSelector: so the hud can refresh
            [self performSelector:@selector(downloadImageForCard:) withObject:@(i+1) afterDelay:.01];
        }
        failure:^(Card* card, NSInteger statusCode, UIImage* placeholder) {
            ++self.imageDownloadErrors;
            
            // use -performSelector: so the hud can refresh
            [self performSelector:@selector(downloadImageForCard:) withObject:@(i+1) afterDelay:.01];
        }];
    }
    else
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [self.alert dismissWithClickedButtonIndex:0 animated:NO];
        if (self.imageDownloadErrors > 0)
        {
            NSString* msg = [NSString stringWithFormat:@"%d of %d images could not be downloaded.", self.imageDownloadErrors, self.cards.count];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
        self.cards = nil;
    }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.imageDownloadStopped = YES;
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
}

@end
