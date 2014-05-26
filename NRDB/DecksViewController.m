//
//  DecksViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DecksViewController.h"
#import "DeckCell.h"
#import "DeckManager.h"
#import "DeckExport.h"
#import "DeckImport.h"
#import "Deck.h"
#import "ImageCache.h"
#import "Faction.h"
#import "Notifications.h"
#import "ImportDecksViewController.h"
#import "SettingsKeys.h"

typedef NS_ENUM(NSInteger, SortType) {
    SortDate, SortFaction, SortA_Z
};
typedef NS_ENUM(NSInteger, FilterType) {
    FilterTypeAll, FilterRunner, FilterCorp
};
typedef NS_ENUM(NSInteger, FilterState) {
    FilterStateAll=-1, FilterActive = NRDeckStateActive, FilterTesting = NRDeckStateTesting, FilterRetired = NRDeckStateRetired
};

enum { POPUP_NEW, POPUP_LONGPRESS, POPUP_SORT, POPUP_SIDE, POPUP_STATE, POPUP_SETSTATE };

static FilterType filterType = FilterTypeAll;
static FilterState filterState = FilterActive;
static SortType sortType = SortA_Z;
static NRDeckSearchScope searchScope = NRDeckSearchAll;
static NSString* filterText;

@interface DecksViewController ()

@property NSMutableArray* runnerDecks;
@property NSMutableArray* corpDecks;
@property NSArray* decks;
@property NSDateFormatter *dateFormatter;
@property UIActionSheet* popup;
@property UIAlertView* nameAlert;
@property Deck* deck;
@property UIBarButtonItem* editButton;
@property UIBarButtonItem* sortButton;
@property UIBarButtonItem* stateFilterButton;
@property UIBarButtonItem* sideFilterButton;

@end

@implementation DecksViewController

static NSDictionary* sortStr;
static NSDictionary* sideStr;
static NSDictionary* stateStr;

+(void) initialize
{
    sortStr = @{ @(SortDate): l10n(@"Date"), @(SortFaction): l10n(@"Faction"), @(SortA_Z): l10n(@"A-Z") };
    sideStr = @{ @(FilterTypeAll): l10n(@"All"), @(FilterRunner): l10n(@"Runner"), @(FilterCorp): l10n(@"Corp") };
    stateStr = @{ @(FilterStateAll): l10n(@"All"), @(FilterRetired): l10n(@"Retired"), @(FilterTesting): l10n(@"Testing"), @(FilterActive): l10n(@"Active") };
}

- (id) init
{
    if ((self = [self initWithNibName:@"DecksViewController" bundle:nil]))
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"DeckCell" bundle:nil] forCellReuseIdentifier:@"deckCell"];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Decks")
                                      style:UIBarButtonItemStylePlain
                                     target:nil
                                     action:nil];
    
    self.sortButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@", l10n(@"Sort"), sortStr[@(sortType)]] style:UIBarButtonItemStylePlain target:self action:@selector(changeSort:)];
    self.sortButton.possibleTitles = [NSSet setWithArray:@[
                                                           [NSString stringWithFormat:@"%@: %@", l10n(@"Sort"), l10n(@"Date")],
                                                           [NSString stringWithFormat:@"%@: %@", l10n(@"Sort"), l10n(@"Faction")],
                                                           [NSString stringWithFormat:@"%@: %@", l10n(@"Sort"), l10n(@"A-Z")],
                                                           ]];
    self.sideFilterButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@", l10n(@"Side"), sideStr[@(filterType)]] style:UIBarButtonItemStylePlain target:self action:@selector(changeSideFilter:)];
    self.sideFilterButton.possibleTitles = [NSSet setWithArray:@[
                                                           [NSString stringWithFormat:@"%@: %@", l10n(@"Side"), l10n(@"All")],
                                                           [NSString stringWithFormat:@"%@: %@", l10n(@"Side"), l10n(@"Runner")],
                                                           [NSString stringWithFormat:@"%@: %@", l10n(@"Side"), l10n(@"Corp")],
                                                           ]];
    self.stateFilterButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@", l10n(@"Status"), stateStr[@(filterState)]] style:UIBarButtonItemStylePlain target:self action:@selector(changeStateFilter:)];
    self.stateFilterButton.possibleTitles = [NSSet setWithArray:@[
                                                                 [NSString stringWithFormat:@"%@: %@", l10n(@"Status"), l10n(@"All")],
                                                                 [NSString stringWithFormat:@"%@: %@", l10n(@"Status"), l10n(@"Active")],
                                                                 [NSString stringWithFormat:@"%@: %@", l10n(@"Status"), l10n(@"Testing")],
                                                                 [NSString stringWithFormat:@"%@: %@", l10n(@"Status"), l10n(@"Retired")],
                                                                 ]];
    
    topItem.leftBarButtonItems = @[
          self.sortButton,
          self.sideFilterButton,
          self.stateFilterButton
    ];
    
    self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEdit:)];
    self.editButton.possibleTitles = [NSSet setWithArray:@[ l10n(@"Edit"), l10n(@"Done") ]];
    self.editButton.title = l10n(@"Edit");
    
    topItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newDeck:)],
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-import"] style:UIBarButtonItemStylePlain target:self action:@selector(importDecks:)],
        self.editButton,
    ];
    
    self.searchBar.placeholder = l10n(@"Search for decks, identities or cards");
    if (filterText.length > 0)
    {
        self.searchBar.text = filterText;
    }
    self.searchBar.scopeButtonTitles = @[ l10n(@"All"), l10n(@"Name"), l10n(@"Identity"), l10n(@"Card") ];
    self.searchBar.selectedScopeButtonIndex = searchScope;
    
    [self.tableView setContentOffset:CGPointMake(0,self.searchBar.frame.size.height) animated:NO];
    
    UIGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.tableView addGestureRecognizer:longPress];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateDecks];
}

-(void) changeSort:(id)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        return;
    }
    
    self.popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"" destructiveButtonTitle:nil otherButtonTitles:l10n(@"Date"), l10n(@"Faction"), l10n(@"A-Z"), nil];
    self.popup.tag = POPUP_SORT;
    [self.popup showFromBarButtonItem:sender animated:NO];
}

-(void) changeSideFilter:(id)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        return;
    }
    
    self.popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"" destructiveButtonTitle:nil otherButtonTitles:l10n(@"All"), l10n(@"Runner"), l10n(@"Corp"), nil];
    self.popup.tag = POPUP_SIDE;
    [self.popup showFromBarButtonItem:sender animated:NO];
}

-(void) changeStateFilter:(id)sender
{
    if (self.popup)
    {
        [self.popup dismissWithClickedButtonIndex:self.popup.cancelButtonIndex animated:NO];
        return;
    }
    
    self.popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"" destructiveButtonTitle:nil otherButtonTitles:l10n(@"All"), l10n(@"Active"), l10n(@"Testing"), l10n(@"Retired"), nil];
    self.popup.tag = POPUP_STATE;
    [self.popup showFromBarButtonItem:sender animated:NO];
}

-(void) importDecks:(UIBarButtonItem*)sender
{
    BOOL useDropbox = [[NSUserDefaults standardUserDefaults] boolForKey:USE_DROPBOX];
    
    if (!useDropbox)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"Import Decks") message:l10n(@"Connect to your Dropbox account first.") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    ImportDecksViewController* import = [[ImportDecksViewController alloc] init];
    [self.navigationController pushViewController:import animated:NO];
}

-(void) updateDecks
{
    [self.sortButton setTitle:[NSString stringWithFormat:@"%@: %@", l10n(@"Sort"), sortStr[@(sortType)]]];
    [self.sideFilterButton setTitle:[NSString stringWithFormat:@"%@: %@", l10n(@"Side"), sideStr[@(filterType)]]];
    [self.stateFilterButton setTitle:[NSString stringWithFormat:@"%@: %@", l10n(@"Status"), stateStr[@(filterState)]]];

    NSArray* runnerDecks = (filterType == FilterRunner || filterType == FilterTypeAll) ? [DeckManager decksForRole:NRRoleRunner] : [NSMutableArray array];
    NSArray* corpDecks = (filterType == FilterCorp || filterType == FilterTypeAll) ? [DeckManager decksForRole:NRRoleCorp] : [NSMutableArray array];
    
    if (sortType != SortDate)
    {
        self.runnerDecks = [self sortDecks:runnerDecks];
        self.corpDecks = [self sortDecks:corpDecks];
    }
    else
    {
        NSMutableArray* arr = [NSMutableArray arrayWithArray:runnerDecks];
        [arr addObjectsFromArray:corpDecks];
        self.runnerDecks = [self sortDecks:arr];
        self.corpDecks = [NSMutableArray array];
    }

    if (filterText.length > 0)
    {
        NSPredicate* namePredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", filterText];
        NSPredicate* identityPredicate = [NSPredicate predicateWithFormat:@"identity.name CONTAINS[cd] %@", filterText];
        NSPredicate* cardPredicate = [NSPredicate predicateWithFormat:@"ANY cards.card.name CONTAINS[cd] %@", filterText];
        
        NSPredicate* predicate;
        switch (searchScope)
        {
            case NRDeckSearchAll:
                predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[ namePredicate, identityPredicate, cardPredicate ]];
                break;
            case NRDeckSearchName:
                predicate = namePredicate;
                break;
            case NRDeckSearchIdentity:
                predicate = identityPredicate;
                break;
            case NRDeckSearchCard:
                predicate = cardPredicate;
                break;
        }
        
        [self.runnerDecks filterUsingPredicate:predicate];
        [self.corpDecks filterUsingPredicate:predicate];
    }
    
    if (filterState != FilterStateAll)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"state == %d", filterState];
        [self.runnerDecks filterUsingPredicate:predicate];
        [self.corpDecks filterUsingPredicate:predicate];
    }
    
    self.decks = @[ self.runnerDecks, self.corpDecks ];
    
    [self.tableView reloadData];
}

-(NSMutableArray*) sortDecks:(NSArray*)decks
{
    switch (sortType)
    {
        case SortA_Z:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
            }];
            break;
        case SortDate:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSComparisonResult cmp = [d2.lastModified compare:d1.lastModified];
                if (cmp == NSOrderedSame)
                {
                    return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
                }
                return cmp;
            }];
            break;
        case SortFaction:
            decks = [decks sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
                NSString* faction1 = [Faction name:d1.identity.faction];
                NSString* faction2 = [Faction name:d2.identity.faction];
                NSComparisonResult cmp = [faction1 compare:faction2];
                if (cmp == NSOrderedSame)
                {
                    cmp = [[d1.identity.name lowercaseString] compare:[d2.identity.name lowercaseString]];
                    if (cmp == NSOrderedSame)
                    {
                        return [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
                    }
                    return cmp;
                }
                return cmp;
            }];
            break;
    }
    
    return [decks mutableCopy];
}

-(void) newDeck:(UIBarButtonItem*)sender
{
    NSNumber* role;
    
    if (filterType == FilterRunner)
    {
        role = @(NRRoleRunner);
    }
    if (filterType == FilterCorp)
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
    }
    else
    {
        self.popup = [[UIActionSheet alloc] initWithTitle:nil
                                                 delegate:self
                                        cancelButtonTitle:@""
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:l10n(@"New Runner Deck"),
                                                          l10n(@"New Corp Deck"), nil];
        self.popup.tag = POPUP_NEW;
        [self.popup showFromBarButtonItem:sender animated:NO];
    }
}

-(void) longPress:(UIGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gesture locationInView:self.tableView];
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:point];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];

        NSArray* decks = self.decks[indexPath.section];
        self.deck = decks[indexPath.row];
        
        self.popup = [[UIActionSheet alloc] initWithTitle:self.deck.name
                                                 delegate:self
                                        cancelButtonTitle:@""
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:l10n(@"Duplicate"),
                                                          l10n(@"Rename"),
                                                          l10n(@"Send via Email"), nil];
        
        self.popup.tag = POPUP_LONGPRESS;
        [self.popup showFromRect:cell.frame inView:self.tableView animated:NO];
    }
}

#pragma mark action sheet

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        self.popup = nil;
        return;
    }
    
    if (actionSheet.tag == POPUP_NEW)
    {
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
    }
    else if (actionSheet.tag == POPUP_LONGPRESS)
    {
        switch (buttonIndex) {
            case 0: // duplicate
            {
                Deck* newDeck = [self.deck duplicate];
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
                self.deck = nil;
                break;
            }
            case 1: // rename
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"Enter Name")
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:l10n(@"Cancel")
                                                      otherButtonTitles:l10n(@"OK"), nil];
                
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                
                UITextField* textField = [alert textFieldAtIndex:0];
                textField.placeholder = l10n(@"Deck Name");
                textField.text = self.deck.name;
                textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                textField.clearButtonMode = UITextFieldViewModeAlways;
                textField.returnKeyType = UIReturnKeyDone;
                textField.delegate = self;
                
                self.nameAlert = alert;
                [alert show];

                break;
            }
            case 2: // email
                [self sendAsEmail];
                break;
        }
    }
    else if (actionSheet.tag == POPUP_SORT)
    {
        switch (buttonIndex)
        {
            case 0:
                sortType = SortDate;
                break;
            case 1:
                sortType = SortFaction;
                break;
            case 2:
                sortType = SortA_Z;
                break;
        }
        [self updateDecks];
    }
    else if (actionSheet.tag == POPUP_SIDE)
    {
        switch (buttonIndex)
        {
            case 0:
                filterType = FilterTypeAll;
                break;
            case 1:
                filterType = FilterRunner;
                break;
            case 2:
                filterType = FilterCorp;
                break;
        }
        [self updateDecks];
    }
    else if (actionSheet.tag == POPUP_STATE)
    {
        switch (buttonIndex)
        {
            case 0:
                filterState = FilterStateAll;
                break;
            case 1:
                filterState = FilterActive;
                break;
            case 2:
                filterState = FilterTesting;
                break;
            case 3:
                filterState = FilterRetired;
                break;
        }
        [self updateDecks];
    }
    else if (actionSheet.tag == POPUP_SETSTATE)
    {
        NRDeckState oldState = self.deck.state;
        switch (buttonIndex)
        {
            case 0:
                self.deck.state = NRDeckStateActive;
                break;
            case 1:
                self.deck.state = NRDeckStateTesting;
                break;
            case 2:
                self.deck.state = NRDeckStateRetired;
                break;
        }
        if (self.deck.state != oldState)
        {
            [DeckManager saveDeck:self.deck toPath:self.deck.filename];
            [self updateDecks];
        }
        self.deck = nil;
    }
    
    self.popup = nil;
    return;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.nameAlert dismissWithClickedButtonIndex:1 animated:NO];
    [textField resignFirstResponder];
    return NO;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        return;
    }
    
    self.deck.name = [alertView textFieldAtIndex:0].text;
    [DeckManager saveDeck:self.deck toPath:self.deck.filename];
    self.deck = nil;
    [self updateDecks];
    
    self.nameAlert = nil;
}

#pragma mark search bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    filterText = searchText;
    [self updateDecks];
}

-(void) searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    searchScope = selectedScope;
    [self updateDecks];
}

#pragma mark edit toggle

-(void) toggleEdit:(id)sender
{
    BOOL editing = self.tableView.editing;
    
    editing = !editing;
    self.editButton.title = editing ? l10n(@"Done") : l10n(@"Edit");
    self.tableView.editing = editing;
}

#pragma mark state popup

-(void)statePopup:(UIButton*)sender
{
    NSInteger row = sender.tag / 10;
    NSInteger section = sender.tag & 1;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    NSArray* decks = self.decks[indexPath.section];
    self.deck = decks[indexPath.row];
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    CGRect frame = [cell.contentView convertRect:sender.frame toView:self.view];
    
    self.popup = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@""
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:
                            [NSString stringWithFormat:@"%@ %@", l10n(@"Active"), self.deck.state == NRDeckStateActive ? @"✓" : @""],
                            [NSString stringWithFormat:@"%@ %@", l10n(@"Testing"), self.deck.state == NRDeckStateTesting ? @"✓" : @""],
                            [NSString stringWithFormat:@"%@ %@", l10n(@"Retired"), self.deck.state == NRDeckStateRetired ? @"✓" : @""], nil];
    
    frame.origin.y -= 990;
    frame.size.height = 2000;
    self.popup.tag = POPUP_SETSTATE;
    [self.popup showFromRect:frame inView:self.tableView.superview animated:NO];
}

#pragma mark tableview

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckCell* cell = [tableView dequeueReusableCellWithIdentifier:@"deckCell" forIndexPath:indexPath];
    
    // [cell.infoButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    cell.infoButton.tag = indexPath.row * 10 + indexPath.section;
    [cell.infoButton addTarget:self action:@selector(statePopup:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = decks[indexPath.row];
    cell.nameLabel.text = deck.name;
    
    if (deck.identity)
    {
        cell.identityLabel.text = deck.identity.name;
        cell.identityLabel.textColor = [deck.identity factionColor];
    }
    else
    {
        cell.identityLabel.text = l10n(@"No Identity");
        cell.identityLabel.textColor = [UIColor darkGrayColor];
    }
    
    NSString* summary;
    
    if (deck.role == NRRoleRunner)
    {
        summary = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence"), deck.size, deck.influence];
    }
    else
    {
        summary = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence · %d AP"), deck.size, deck.influence, deck.agendaPoints];
    }
    cell.summaryLabel.text = summary;
    BOOL valid = [deck checkValidity].count == 0;
    cell.summaryLabel.textColor = valid ? [UIColor blackColor] : [UIColor redColor];
    
    NSString* state = stateStr[@(deck.state)];
    NSString* date = [self.dateFormatter stringFromDate:deck.lastModified];
    cell.dateLabel.text = [NSString stringWithFormat:@"%@ · %@", state, date];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* decks = self.decks[indexPath.section];
    Deck* deck = [decks objectAtIndex:indexPath.row];
    
    TF_CHECKPOINT(@"load deck");
    
    NSDictionary* userInfo = @{
                               @"filename" : deck.filename,
                               @"role" : @(deck.role)
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_DECK object:self userInfo:userInfo];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSMutableArray* decks = self.decks[indexPath.section];
        Deck* deck = [decks objectAtIndex:indexPath.row];
        
        [decks removeObjectAtIndex:indexPath.row];
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

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0: return self.runnerDecks.count;
        case 1: return self.corpDecks.count;
    }
    return 0;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (sortType == SortDate)
    {
        return nil;
    }
    switch (section)
    {
        case 0: return self.runnerDecks.count > 0 ? l10n(@"Runner") : nil;
        case 1: return self.corpDecks.count > 0 ? l10n(@"Corp") : nil;
    }
    return nil;
}

#pragma mark email

-(void) sendAsEmail
{
    TF_CHECKPOINT(@"Send as Email");
    
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    
    mailer.mailComposeDelegate = self;
    NSString *emailBody = [DeckExport asPlaintextString:self.deck];
    [mailer setMessageBody:emailBody isHTML:NO];
    
    [mailer setSubject:self.deck.name];
    
    [self presentViewController:mailer animated:NO completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
