//
//  SavedDecksList.m
//  Net Deck
//
//  Created by Gereon Steffens on 15.07.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import SVProgressHUD;

#import "SavedDecksList.h"
#import "ImportDecksViewController.h"
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
    
    self.toolBarHeight.constant = 0;
}

// WTF is this necessary? if we don't do this, the import/export/add buttons will appear inactive after we return here from
// the import view
-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItems = nil;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItems = self.normalRightButtons;
}

-(void) importDecks:(UIBarButtonItem*)sender
{
    if (self.popup)
    {
        [self.popup dismissViewControllerAnimated:NO completion:nil];
        self.popup = nil;
        return;
    }
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    BOOL useDropbox = [settings boolForKey:SettingsKeys.USE_DROPBOX];
    BOOL useNetrunnerdb = [settings boolForKey:SettingsKeys.USE_NRDB];
    
    if (!useDropbox && !useNetrunnerdb)
    {
        [UIAlertController alertWithTitle:l10n(@"Import Decks")
                                  message:l10n(@"Connect to your Dropbox and/or NetrunnerDB.com account first.")
                                   button:l10n(@"OK")];
        return;
    }
    
    if (useDropbox && useNetrunnerdb)
    {
        self.popup = [UIAlertController actionSheetWithTitle:nil message:nil];
        [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Import from Dropbox") handler:^(UIAlertAction *action) {
            [self importFromSource:NRImportSourceDropbox];
        }]];
        [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Import from NetrunnerDB.com") handler:^(UIAlertAction *action) {
            [self importFromSource:NRImportSourceNetrunnerDb];
        }]];
        [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
            self.popup = nil;
        }]];
        
        UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
        popover.barButtonItem = sender;
        popover.sourceView = self.view;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [self.popup.view layoutIfNeeded];
        
        [self presentViewController:self.popup animated:NO completion:nil];
    }
    else
    {
        NRImportSource src;
        if (useDropbox && !useNetrunnerdb)
        {
            src = NRImportSourceDropbox;
        }
        else
        {
            src = NRImportSourceNetrunnerDb;
        }
        [self importFromSource:src];
    }
}

-(void) importFromSource:(NRImportSource) importSource
{
    ImportDecksViewController* import = [[ImportDecksViewController alloc] init];
    import.source = importSource;
    [self.navigationController pushViewController:import animated:NO];
    self.popup = nil;
}

-(void) exportDecks:(id)sender
{
    if (self.popup)
    {
        [self.popup dismissViewControllerAnimated:NO completion:nil];
        self.popup = nil;
        return;
    }
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    BOOL useDropbox = [settings boolForKey:SettingsKeys.USE_DROPBOX];
    BOOL useNetrunnerdb = [settings boolForKey:SettingsKeys.USE_NRDB];
    
    if (!useDropbox && !useNetrunnerdb)
    {
        [UIAlertController alertWithTitle:l10n(@"Export Decks")
                                  message:l10n(@"Connect to your Dropbox and/or NetrunnerDB.com account first.")
                                   button:l10n(@"OK")];
        return;
    }
    
    UIAlertController* alert = [UIAlertController alertWithTitle:l10n(@"Export Decks")
                                                         message:l10n(@"Export all currently visible decks")];
    
    [alert addAction:[UIAlertAction cancelAlertAction:nil]];
    if (useDropbox) {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"To Dropbox") handler:^(UIAlertAction * action) {
            [SVProgressHUD showWithStatus:l10n(@"Exporting Decks...")];
            [self performSelector:@selector(exportAllToDropbox) withObject:nil afterDelay:0.0];
        }]];
    }
    if (useNetrunnerdb) {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"To NetrunnerDB.com") handler:^(UIAlertAction * action) {
            [SVProgressHUD showWithStatus:l10n(@"Exporting Decks...")];
            [self performSelector:@selector(exportAllToNetrunnerDB) withObject:nil afterDelay:0.0];
        }]];
    }
    
    [alert show];
}

-(void) exportAllToDropbox
{
    for (NSArray* arr in self.decks)
    {
        for (Deck* deck in arr)
        {
            if (deck.identity)
            {
                [DeckExport asOctgn:deck autoSave:YES];
            }
        }
    }
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

-(void) exportToNetrunnerDB:(NSArray<Deck*>*)decks index:(NSInteger)index
{
    if (index < decks.count)
    {
        // NSLog(@"export deck %d", index);
        Deck* deck = [decks objectAtIndex:index];
        [[NRDB sharedInstance] saveDeck:deck completion:^(BOOL ok, NSString* deckId, NSString* msg) {
            // NSLog(@"saved %d, ok=%d id=%@", index, ok, deckId);
            if (ok && deckId)
            {
                deck.netrunnerDbId = deckId;
                [deck saveToDisk];
            }
            [self exportToNetrunnerDB:decks index:index+1];
        }];
    }
    else
    {
        // NSLog(@"export done");
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

    Deck* deck = [self.decks objectAtIndexPath:indexPath];
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    self.popup = [UIAlertController actionSheetWithTitle:nil message:nil];
    
    [self.popup addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Active"), deck.state == NRDeckStateActive) handler:^(UIAlertAction *action) {
        [self changeState:deck newState:NRDeckStateActive];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Testing"), deck.state == NRDeckStateTesting) handler:^(UIAlertAction *action) {
        [self changeState:deck newState:NRDeckStateTesting];
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Retired"), deck.state == NRDeckStateRetired) handler:^(UIAlertAction *action) {
        [self changeState:deck newState:NRDeckStateRetired];
    }]];
    [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
        self.popup = nil;
    }]];
    
    CGRect frame = [cell.contentView convertRect:sender.frame toView:self.view];

    UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
    popover.sourceView = self.view;
    popover.sourceRect = frame;
    popover.permittedArrowDirections = UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight;
    [self.popup.view layoutIfNeeded];
    
    [self presentViewController:self.popup animated:NO completion:nil];
}

-(void) changeState:(Deck*)deck newState:(NRDeckState)newState
{
    NRDeckState oldState = deck.state;
    deck.state = newState;
    if (deck.state != oldState)
    {
        [deck updateOnDisk];
        [self updateDecks];
    }
    self.popup = nil;
}

-(void) newDeck:(id)sender
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
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.newDeck object:self userInfo:@{ @"role": role}];
        return;
    }
    
    if (self.popup)
    {
        [self.popup dismissViewControllerAnimated:NO completion:nil];
        self.popup = nil;
        return;
    }

    self.popup = [UIAlertController actionSheetWithTitle:nil message:nil];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"New Runner Deck") handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.newDeck object:self userInfo:@{ @"role": @(NRRoleRunner)}];
        self.popup = nil;
    }]];
    [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"New Corp Deck") handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.newDeck object:self userInfo:@{ @"role": @(NRRoleCorp)}];
        self.popup = nil;
    }]];
    [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
        self.popup = nil;
    }]];
    
    UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        popover.barButtonItem = sender;
        popover.sourceView = self.view;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    } else if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* btn = (UIButton*)sender;
        popover.sourceRect = [btn.superview convertRect:btn.frame toView:self.tableView];
        popover.sourceView = self.tableView;
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    } else {
        NSAssert(NO, @"oops");
    }
    
    [self.popup.view layoutIfNeeded];
    [self presentViewController:self.popup animated:NO completion:nil];
}

-(void) longPress:(UIGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gesture locationInView:self.tableView];
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if (indexPath)
        {
            Deck* deck = [self.decks objectAtIndexPath:indexPath];

            self.popup = [UIAlertController actionSheetWithTitle:nil message:nil];
            [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Duplicate") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                Deck* newDeck = [deck duplicate];
                [newDeck saveToDisk];
                
                NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
                BOOL autoSaveDropbox = [settings boolForKey:SettingsKeys.USE_DROPBOX] && [settings boolForKey:SettingsKeys.AUTO_SAVE_DB];
                
                if (autoSaveDropbox)
                {
                    if (newDeck.identity && newDeck.cards.count > 0)
                    {
                        [DeckExport asOctgn:newDeck autoSave:YES];
                    }
                }
                
                [self updateDecks];
                self.popup = nil;
            }]];
            [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Rename") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                BOOL searchBarActive = self.searchBar.isFirstResponder;
                if (searchBarActive) {
                    [self.searchBar resignFirstResponder];
                }
                
                UIAlertController* nameAlert = [UIAlertController alertWithTitle:l10n(@"Enter Name")
                                                                                   message:nil];
                
                [nameAlert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
                    textField.placeholder = l10n(@"Deck Name");
                    textField.text = deck.name;
                    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                    textField.clearButtonMode = UITextFieldViewModeAlways;
                    textField.returnKeyType = UIReturnKeyDone;
                }];
                [nameAlert addAction:[UIAlertAction cancelAlertAction:nil]];
                [nameAlert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction * action) {
                    deck.name = nameAlert.textFields[0].text;
                    [deck saveToDisk];
                    [self updateDecks];
                    
                    if (searchBarActive)
                    {
                        [self.searchBar becomeFirstResponder];
                    }
                }]];
                
                [nameAlert show];
                
                self.popup = nil;
            }]];
            if ([MFMailComposeViewController canSendMail])
            {
                [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Send via Email") handler:^(UIAlertAction *action) {
                    [DeckEmail emailDeck:deck fromViewController:self];
                    self.popup = nil;
                }]];
            }
            [self.popup addAction:[UIAlertAction actionWithTitle:l10n(@"Compare to ...") handler:^(UIAlertAction *action) {
                self.diffDeck = deck.filename;
                self.diffSelection = YES;
                self.navigationController.navigationBar.topItem.rightBarButtonItems = self.diffRightButtons;
                
                [self.tableView reloadData];
                self.popup = nil;
            }]];
            [self.popup addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
                self.popup = nil;
            }]];
            
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UIPopoverPresentationController* popover = self.popup.popoverPresentationController;
            popover.sourceRect = cell.frame;
            popover.sourceView = self.tableView;
            popover.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
            [self.popup.view layoutIfNeeded];
            
            [self presentViewController:self.popup animated:NO completion:nil];
        }
    }
}

#pragma mark edit toggle

-(void) toggleEdit:(id)sender
{
    if (self.popup)
    {
        [self.popup dismissViewControllerAnimated:NO completion:nil];
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
    
    Deck* deck = [self.decks objectAtIndexPath:indexPath];

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
    UIImage* img = [[UIImage imageNamed:icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [cell.infoButton setImage:img forState:UIControlStateNormal];

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
    Deck* deck = [self.decks objectAtIndexPath:indexPath];
    
    if (self.diffSelection)
    {
        NSAssert(self.diffDeck, @"no diff deck");
        Deck* d = [DeckManager loadDeckFromPath:self.diffDeck];
        if (d.role != deck.role)
        {
            [UIAlertController alertWithTitle:nil message:l10n(@"Both decks must be for the same side.") button:l10n(@"OK")];
            return;
        }

        [DeckDiffViewController showForDecks:d deck2:deck inViewController:self];
    }
    else
    {
        NSDictionary* userInfo = @{
                                   @"filename" : deck.filename,
                                   @"role" : @(deck.role)
                                   };
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.loadDeck object:self userInfo:userInfo];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        Deck* deck = [self.decks objectAtIndexPath:indexPath];
        
        NSMutableArray* decks = self.decks[indexPath.section];
        [decks removeObjectAtIndex:indexPath.row];
        
        [[NRDB sharedInstance] deleteDeck:deck.netrunnerDbId];
        [DeckManager removeFile:deck.filename];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView endUpdates];
        
        // need to force all infobutton tags to be reset
        [self.tableView reloadData];
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

#pragma mark - empty set

- (NSAttributedString*) buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    UIColor* color = self.tableView.tintColor;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0f], NSForegroundColorAttributeName: color };
    
    return [[NSAttributedString alloc] initWithString:l10n(@"New Deck") attributes:attributes];
}

-(void) emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    [self newDeck:button];
}

@end
