//
//  SavedDecksList.m
//  NRDB
//
//  Created by Gereon Steffens on 15.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>
#import <SVProgressHud.h>
#import <EXTScope.h>

#import "NRActionSheet.h"
#import "SavedDecksList.h"
#import "Deck.h"
#import "ImportDecksViewController.h"
#import "SettingsKeys.h"
#import "NRDB.h"
#import "DeckManager.h"
#import "DeckExport.h"
#import "Notifications.h"
#import "DeckDiffViewController.h"
#import "DeckCell.h"

@interface SavedDecksList ()

@property UIBarButtonItem* editButton;
@property UIBarButtonItem* importButton;
@property UIBarButtonItem* exportButton;
@property UIBarButtonItem* addDeckButton;

@property UIBarButtonItem* diffCancelButton;

@property NSArray* normalRightButtons;
@property NSArray* diffRightButtons;

@property SDCAlertView* nameAlert;

@property BOOL diffSelection;
@property NSString* diffDeck;

@end

@implementation SavedDecksList

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self.diffSelection = NO;
    
    self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEdit:)];
    self.editButton.possibleTitles = [NSSet setWithArray:@[ l10n(@"Edit"), l10n(@"Done") ]];
    self.editButton.title = l10n(@"Edit");
    
    self.diffCancelButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(diffCancel:)];
    self.diffRightButtons = @[ self.diffCancelButton ];
    
    self.addDeckButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newDeck:)];
    self.importButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-import"] style:UIBarButtonItemStylePlain target:self action:@selector(importDecks:)];
    self.exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"] style:UIBarButtonItemStylePlain target:self action:@selector(exportDecks:)];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    self.normalRightButtons = @[
        self.addDeckButton,
        self.exportButton,
        self.importButton,
        self.editButton,
    ];
    topItem.rightBarButtonItems = self.normalRightButtons;
    
    UIGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.tableView addGestureRecognizer:longPress];
}

-(void) importDecks:(UIBarButtonItem*)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        self.popup = nil;
        return;
    }
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    BOOL useDropbox = [settings boolForKey:USE_DROPBOX];
    BOOL useNetrunnerdb = [settings boolForKey:USE_NRDB];
    
    if (!useDropbox && !useNetrunnerdb)
    {
        [SDCAlertView alertWithTitle:l10n(@"Import Decks")
                             message:l10n(@"Connect to your Dropbox and/or NetrunnerDB.com account first.")
                             buttons:@[l10n(@"OK")]];
        return;
    }
    
    if (useDropbox && useNetrunnerdb)
    {
        self.popup = [[NRActionSheet alloc] initWithTitle:nil
                                                 delegate:nil
                                        cancelButtonTitle:@""
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:l10n(@"Import from Dropbox"), l10n(@"Import from NetrunnerDB.com"), nil];

        [self.popup showFromBarButtonItem:sender animated:NO action:^(NSInteger buttonIndex) {
            ImportDecksViewController* import = [[ImportDecksViewController alloc] init];
            if (buttonIndex == 0)
            {
                import.source = NRImportSourceDropbox;
            }
            else
            {
                import.source = NRImportSourceNetrunnerDb;
            }
            [self.navigationController pushViewController:import animated:NO];
        }];
    }
    else
    {
        ImportDecksViewController* import = [[ImportDecksViewController alloc] init];
        if (useDropbox && !useNetrunnerdb)
        {
            import.source = NRImportSourceDropbox;
        }
        else
        {
            import.source = NRImportSourceNetrunnerDb;
        }
        [self.navigationController pushViewController:import animated:NO];
    }
}

-(void) exportDecks:(id)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        self.popup = nil;
        return;
    }
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    BOOL useDropbox = [settings boolForKey:USE_DROPBOX];
    BOOL useNetrunnerdb = [settings boolForKey:USE_NRDB];
    
    if (!useDropbox && !useNetrunnerdb)
    {
        [SDCAlertView alertWithTitle:l10n(@"Export Decks")
                             message:l10n(@"Connect to your Dropbox and/or NetrunnerDB.com account first.")
                             buttons:@[l10n(@"OK")]];
        return;
    }
    
    NSMutableArray* buttons = [NSMutableArray array];
    NSInteger dbButton = 0;
    NSInteger nrdbButton = 0;
    [buttons addObject:l10n(@"Cancel")];
    if (useDropbox)
    {
        [buttons addObject:l10n(@"To Dropbox")];
        dbButton = 1;
    }
    if (useNetrunnerdb)
    {
        [buttons addObject:l10n(@"To NetrunnerDB.com")];
        nrdbButton = dbButton + 1;
    }
    
    SDCAlertView* alert = [SDCAlertView alertWithTitle:l10n(@"Export Decks")
                                               message:l10n(@"Export all currently visible decks")
                                               buttons:buttons];
    alert.didDismissHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 0) // cancel
        {
            return;
        }
        if (buttonIndex == dbButton)
        {
            [SVProgressHUD showWithStatus:l10n(@"Exporting Decks...")];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [self performSelector:@selector(exportAllToDropbox) withObject:nil afterDelay:0.01];
        }
        if (buttonIndex == nrdbButton)
        {
            [SVProgressHUD showWithStatus:l10n(@"Exporting Decks...")];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [self performSelector:@selector(exportAllToNetrunnerDB) withObject:nil afterDelay:0.01];
        }
    };
}

-(void) exportAllToDropbox
{
    for (NSArray* arr in self.decks)
    {
        for (Deck* deck in arr)
        {
            [DeckExport asOctgn:deck autoSave:YES];
        }
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
}

-(void) exportAllToNetrunnerDB
{
    NSMutableArray* decks = [NSMutableArray array];
    for (NSArray* arr in self.decks)
    {
        for (Deck* deck in arr)
        {
            [decks addObject:deck];
        }
    }
    [self exportToNetrunnerDB:decks index:0];
}

-(void) exportToNetrunnerDB:(NSArray*)decks index:(NSInteger)index
{
    if (index < decks.count)
    {
        // NSLog(@"export deck %d", index);
        Deck* deck = [decks objectAtIndex:index];
        [[NRDB sharedInstance] saveDeck:deck completion:^(BOOL ok, NSString* deckId) {
            // NSLog(@"saved %d, ok=%d id=%@", index, ok, deckId);
            if (ok && deckId)
            {
                deck.netrunnerDbId = deckId;
                [DeckManager saveDeck:deck];
                [DeckManager resetModificationDate:deck];
            }
            [self exportToNetrunnerDB:decks index:index+1];
        }];
    }
    else
    {
        // NSLog(@"export done");
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [SVProgressHUD dismiss];
        [self updateDecks];
    }
}

#pragma mark state popup

-(void)statePopup:(UIButton*)sender
{
    NSInteger row = sender.tag / 10;
    NSInteger section = sender.tag & 1;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    NSArray* decks = self.decks[indexPath.section];

    Deck* deck = decks[indexPath.row];
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    CGRect frame = [cell.contentView convertRect:sender.frame toView:self.view];
    
    self.popup = [[NRActionSheet alloc] initWithTitle:nil
                                             delegate:nil
                                    cancelButtonTitle:@""
                               destructiveButtonTitle:nil
                                    otherButtonTitles:
                  [NSString stringWithFormat:@"%@%@", l10n(@"Active"), deck.state == NRDeckStateActive ? @" ✓" : @""],
                  [NSString stringWithFormat:@"%@%@", l10n(@"Testing"), deck.state == NRDeckStateTesting ? @" ✓" : @""],
                  [NSString stringWithFormat:@"%@%@", l10n(@"Retired"), deck.state == NRDeckStateRetired ? @" ✓" : @""], nil];
    
    // fudge the frame so the popup appears to the left of the (I)
    frame.origin.y -= 990;
    frame.size.height = 2000;
    frame.size.width = 500;
    
    [self.popup showFromRect:frame inView:self.tableView.superview animated:NO action:^(NSInteger buttonIndex) {
        NRDeckState oldState = deck.state;
        switch (buttonIndex)
        {
            case 0:
                deck.state = NRDeckStateActive;
                break;
            case 1:
                deck.state = NRDeckStateTesting;
                break;
            case 2:
                deck.state = NRDeckStateRetired;
                break;
        }
        if (deck.state != oldState)
        {
            [DeckManager saveDeck:deck];
            [DeckManager resetModificationDate:deck];
            
            [self updateDecks];
        }
    }];
}

-(void) newDeck:(UIBarButtonItem*)sender
{
    NSNumber* role;
    
    if (self.filterType == NRFilterRunner)
    {
        role = @(NRRoleRunner);
    }
    if (self.filterType == NRFilterCorp)
    {
        role = @(NRRoleCorp);
    }
    if (role)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_DECK object:self userInfo:@{ @"role": role}];
        return;
    }
    
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        self.popup = nil;
        return;
    }

    self.popup = [[NRActionSheet alloc] initWithTitle:nil
                                             delegate:nil
                                    cancelButtonTitle:@""
                               destructiveButtonTitle:nil
                                    otherButtonTitles:l10n(@"New Runner Deck"),
                  l10n(@"New Corp Deck"), nil];
    
    [self.popup showFromBarButtonItem:sender animated:NO action:^(NSInteger buttonIndex) {
        NSNumber* role;
        switch (buttonIndex)
        {
            case 0: // new runner
                role = @(NRRoleRunner);
                break;
            case 1: // new corp
                role = @(NRRoleCorp);
                break;
        }
        if (role)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NEW_DECK object:self userInfo:@{ @"role": role}];
        }
    }];
}

-(void) longPress:(UIGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gesture locationInView:self.tableView];
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if (indexPath)
        {
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            NSArray* decks = self.decks[indexPath.section];
            Deck* deck = decks[indexPath.row];
            
            self.popup = [[NRActionSheet alloc] initWithTitle:deck.name
                                                     delegate:nil
                                            cancelButtonTitle:@""
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:l10n(@"Duplicate"),
                          l10n(@"Rename"),
                          l10n(@"Send via Email"),
                          l10n(@"Compare to ..."), nil];
            
            [self.popup showFromRect:cell.frame inView:self.tableView animated:NO action:^(NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 0: // duplicate
                    {
                        Deck* newDeck = [deck duplicate];
                        [DeckManager saveDeck:newDeck];
                        
                        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
                        BOOL autoSaveDropbox = [settings boolForKey:USE_DROPBOX] && [settings boolForKey:AUTO_SAVE_DB];
                        
                        if (autoSaveDropbox)
                        {
                            if (newDeck.identity && newDeck.cards.count > 0)
                            {
                                [DeckExport asOctgn:newDeck autoSave:YES];
                            }
                        }
                        
                        [self updateDecks];
                        break;
                    }
                    case 1: // rename
                    {
                        self.nameAlert = [[SDCAlertView alloc] initWithTitle:l10n(@"Enter Name")
                                                                     message:nil
                                                                    delegate:nil
                                                           cancelButtonTitle:l10n(@"Cancel")
                                                           otherButtonTitles:l10n(@"OK"), nil];
                        
                        self.nameAlert.alertViewStyle = SDCAlertViewStylePlainTextInput;
                        
                        UITextField* textField = [self.nameAlert textFieldAtIndex:0];
                        textField.placeholder = l10n(@"Deck Name");
                        textField.text = deck.name;
                        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                        textField.clearButtonMode = UITextFieldViewModeAlways;
                        textField.returnKeyType = UIReturnKeyDone;
                        textField.delegate = self;
                        
                        @weakify(self);
                        [self.nameAlert showWithDismissHandler:^(NSInteger buttonIndex) {
                            @strongify(self);
                            if (buttonIndex == 1)
                            {
                                deck.name = [self.nameAlert textFieldAtIndex:0].text;
                                [DeckManager saveDeck:deck];
                                [self updateDecks];
                            }
                            self.nameAlert = nil;
                        }];
                        
                        break;
                    }
                    case 2: // email
                        [self sendAsEmail:deck];
                        break;
                    case 3: // select for diff
                        self.diffDeck = deck.filename;
                        self.diffSelection = YES;
                        self.navigationController.navigationBar.topItem.rightBarButtonItems = self.diffRightButtons;
                        
                        [self.tableView reloadData];
                        break;
                }
            }];
        }
    }
}

#pragma mark edit toggle

-(void) toggleEdit:(id)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        self.popup = nil;
        return;
    }
    
    BOOL editing = self.tableView.editing;
    
    editing = !editing;
    self.editButton.title = editing ? l10n(@"Done") : l10n(@"Edit");
    self.tableView.editing = editing;
    
    self.sortButton.enabled = !editing;
    self.sideFilterButton.enabled = !editing;
    self.stateFilterButton.enabled = !editing;
    self.importButton.enabled = !editing;
    self.exportButton.enabled = !editing;
    self.addDeckButton.enabled = !editing;
}

#pragma mark deck diff

-(void) diffCancel:(id)sender
{
    NSAssert(self.diffSelection, @"not in diff mode");
    self.diffSelection = NO;
    
    self.diffDeck = nil;
    [self.tableView reloadData];
    
    self.navigationController.navigationBar.topItem.rightBarButtonItems = self.normalRightButtons;
}

#pragma mark table view

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckCell* cell = (DeckCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    cell.infoButton.hidden = NO;
    cell.infoButton.tag = indexPath.row * 10 + indexPath.section;
    [cell.infoButton addTarget:self action:@selector(statePopup:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    
    NSString* icon;
    switch (deck.state)
    {
        case NRDeckStateActive: icon = @"active";
            break;
        case NRDeckStateRetired: icon = @"retired";
            break;
        case NRDeckStateNone:
        case NRDeckStateTesting: icon = @"testing";
            break;
    }
    [cell.infoButton setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];

    if ([self.diffDeck isEqualToString:deck.filename])
    {
        cell.nameLabel.textColor = [UIColor blueColor];
    }
    else
    {
        cell.nameLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = [decks objectAtIndex:indexPath.row];
    
    if (self.diffSelection)
    {
        NSAssert(self.diffDeck, @"no diff deck");
        Deck* d = [DeckManager loadDeckFromPath:self.diffDeck];
        if (d.role != deck.role)
        {
            [SDCAlertView alertWithTitle:nil message:l10n(@"Both decks must be for the same side.") buttons:@[ l10n(@"OK")]];
            return;
        }

        [DeckDiffViewController showForDecks:d deck2:deck inViewController:self];
    }
    else
    {
        TF_CHECKPOINT(@"load deck");
        
        NSDictionary* userInfo = @{
                                   @"filename" : deck.filename,
                                   @"role" : @(deck.role)
                                   };
        [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_DECK object:self userInfo:userInfo];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSMutableArray* decks = self.decks[indexPath.section];
        Deck* deck = [decks objectAtIndex:indexPath.row];
        
        [decks removeObjectAtIndex:indexPath.row];
        [[NRDB sharedInstance] deleteDeck:deck.netrunnerDbId];
        [DeckManager removeFile:deck.filename];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView endUpdates];
    }
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.nameAlert dismissWithClickedButtonIndex:1 animated:NO];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark email

-(void) sendAsEmail:(Deck*)deck
{
    TF_CHECKPOINT(@"Send as Email");
    
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    
    mailer.mailComposeDelegate = self;
    NSString *emailBody = [DeckExport asPlaintextString:deck];
    [mailer setMessageBody:emailBody isHTML:NO];
    
    [mailer setSubject:deck.name];
    
    [self presentViewController:mailer animated:NO completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
