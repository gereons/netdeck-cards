//
//  EditDeckViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "EditDeckViewController.h"
#import "ListCardsViewController.h"
#import "CardImageViewController.h"
#import "IphoneIdentityViewController.h"
#import "IphoneDrawSimulator.h"
#import "EditDeckCell.h"
#import "SVProgressHud.h"

@interface EditDeckViewController ()

@property BOOL autoSave;
@property BOOL autoSaveDropbox;
@property BOOL autoSaveNrdb;

@property NSArray* cards;
@property NSArray* sections;

@property UIButton* titleButton;  // used as the titleView in our navigation bar

@property UIBarButtonItem* cancelButton;
@property UIBarButtonItem* saveButton;
@property UIBarButtonItem* exportButton;
@property UIBarButtonItem* historyButton;

@property ListCardsViewController* listCards;
@property NRDeckSort sortType;

@property UITapGestureRecognizer* tapRecognizer;

@end

@implementation EditDeckViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EditDeckCell" bundle:nil] forCellReuseIdentifier:@"cardCell"];
    
    self.statusLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.statusLabel.text = @"";
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    self.autoSave = [settings boolForKey:SettingsKeys.AUTO_SAVE];
    self.autoSaveDropbox = self.autoSave && [settings boolForKey:SettingsKeys.AUTO_SAVE_DB];
    self.autoSaveNrdb = [settings boolForKey:SettingsKeys.NRDB_AUTOSAVE];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelClicked:)];
    self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveClicked:)];
    
    self.sortType = [settings integerForKey:SettingsKeys.DECK_VIEW_SORT];
    
    self.statusLabel.textColor = self.view.tintColor;
    self.statusLabel.userInteractionEnabled = YES;
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statusTapped:)];
    [self.statusLabel addGestureRecognizer:self.tapRecognizer];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSAssert(self.navigationController.viewControllers.count == 2, @"nav oops");
    
    // right button
    self.exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(exportDeck:)];
    
    self.historyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"718-timer-1"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(showEditHistory:)];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItems = @[ self.exportButton, self.historyButton ];

    self.titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.titleButton addTarget:self action:@selector(titleTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.titleButton.titleLabel.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightMedium];
    self.titleButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleButton.titleLabel.minimumScaleFactor = 0.5;
    
    [self setDeckName];
    topItem.titleView = self.titleButton;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_NRDB])
    {
        self.nrdbButton.customView = [[UIView alloc] initWithFrame:CGRectZero];
        self.nrdbButton.enabled = NO;
    }
    
    [self refreshDeck];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@(self.sortType) forKey:SettingsKeys.DECK_VIEW_SORT];
}

-(void) setupNavigationButtons:(BOOL)modified
{
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    if (modified) {
        topItem.leftBarButtonItem = self.cancelButton;
        topItem.rightBarButtonItems = @[ self.saveButton, self.historyButton ];
    } else {
        topItem.leftBarButtonItem = nil;
        topItem.rightBarButtonItems = @[ self.exportButton, self.historyButton ];
    }
}

#pragma mark - deck name

-(void) setDeckName
{
    [self.titleButton setTitle:self.deck.name forState:UIControlStateNormal];
    [self.titleButton sizeToFit];
    
    self.title = self.deck.name;
    
    [self doAutoSave];
    [self setupNavigationButtons:self.deck.modified];
}

-(void) titleTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertWithTitle:l10n(@"Enter Name") message:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.deck.name;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.returnKeyType = UIReturnKeyDone;
        textField.clearButtonMode = UITextFieldViewModeAlways;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction *action) {
        UITextField* textField = alert.textFields.firstObject;
        self.deck.name = textField.text;
        [self setDeckName];
    }]];
    [alert addAction:[UIAlertAction cancelAction:nil]];
    
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - export 

-(void) exportDeck:(id)sender
{
    UIAlertController* alert = [UIAlertController actionSheetWithTitle:l10n(@"Export") message:nil];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if ([settings boolForKey:SettingsKeys.USE_DROPBOX])
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"To Dropbox") handler:^(UIAlertAction *action) {
            LOG_EVENT(@"Export .o8d", nil);
            [DeckExport asOctgn:self.deck autoSave:NO];
        }]];
    }
    
    if ([settings boolForKey:SettingsKeys.USE_NRDB])
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"To NetrunnerDB.com") handler:^(UIAlertAction *action) {
            LOG_EVENT(@"Save to NRDB", nil);
            [self saveToNrdb];
        }]];
    }
    
    if ([MFMailComposeViewController canSendMail])
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"As Email") handler:^(UIAlertAction *action) {
            LOG_EVENT(@"Email Deck", nil);
            [DeckEmail emailDeck:self.deck fromViewController:self];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Duplicate Deck") handler:^(UIAlertAction * _Nonnull action) {
        Deck* newDeck = [self.deck duplicate];
        [newDeck saveToDisk];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:l10n(@"Copy saved as %@"), newDeck.name]];
    }]];
    
    [alert addAction:[UIAlertAction cancelAction:nil]];
    [alert.view layoutIfNeeded];
    
    [self presentViewController:alert animated:NO completion:nil];
}

-(void) showEditHistory:(id)sender {
    DeckHistoryViewController* histController = [DeckHistoryViewController new];
    
    [self.deck mergeRevisions];
    histController.deck = self.deck;
    
    [self.navigationController pushViewController:histController animated:YES];
}

-(void) drawClicked:(id)sender
{
    IphoneDrawSimulator* draw = [[IphoneDrawSimulator alloc] initWithNibName:@"IphoneDrawSimulator" bundle:nil];
    draw.deck = self.deck;
    [self.navigationController pushViewController:draw animated:YES];
}

#pragma mark - sort

-(void)sortClicked:(id)sender {
    UIAlertController* actionSheet = [UIAlertController actionSheetWithTitle:l10n(@"Sort") message:nil];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Type"), self.sortType == NRDeckSortByType)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
                                                      [self changeDeckSort:NRDeckSortByType];
                                                  }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Faction"), self.sortType == NRDeckSortByFactionType)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
                                                      [self changeDeckSort:NRDeckSortByFactionType];
                                                  }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Set/Type"), self.sortType == NRDeckSortBySetType)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
                                                      [self changeDeckSort:NRDeckSortBySetType];
                                                  }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Set/Number"), self.sortType == NRDeckSortBySetNum)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
                                                      [self changeDeckSort:NRDeckSortBySetNum];
                                                  }]];
    [actionSheet addAction:[UIAlertAction cancelAction:nil]];
    
    [self presentViewController:actionSheet animated:NO completion:nil];
}

-(void) changeDeckSort:(NRDeckSort) sort {
    self.sortType = sort;
    [self refreshDeck];
}

#pragma mark - netrunnerdb.com

-(void) nrdbButtonClicked:(id)sender
{
    UIAlertController* alert = [UIAlertController actionSheetWithTitle:@"NetrunnerDB.com" message:nil];
    
    if (self.deck.netrunnerDbId.length > 0)
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Save") handler:^(UIAlertAction *action) {
            [self saveToNrdb];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Reimport") handler:^(UIAlertAction *action) {
            [self reImportDeckFromNetrunnerDb];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Publish deck") handler:^(UIAlertAction *action) {
            [self publishDeck];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Unlink") handler:^(UIAlertAction *action) {
            self.deck.netrunnerDbId = nil;
            [self doAutoSave];
        }]];
    }
    else
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Save") handler:^(UIAlertAction *action) {
            [self saveToNrdb];
        }]];
    }
    
    [alert addAction:[UIAlertAction cancelAction:nil]];
    [alert.view layoutIfNeeded];
    
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - save

-(void) cancelClicked:(id)sender
{
    if (self.deck.filename) {
        self.deck = [DeckManager loadDeckFromPath:self.deck.filename useCache:NO];
        [self refreshDeck];
        [self setupNavigationButtons:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void) saveClicked:(id)sender
{
    [self.deck mergeRevisions];
    [self.deck saveToDisk];
    
    if (self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
    if (self.autoSaveNrdb && self.deck.netrunnerDbId && Reachability.online)
    {
        [self saveToNrdb];
    }
    
    [self setupNavigationButtons:self.deck.modified];
}

-(void) doAutoSave
{
    BOOL modified = self.deck.modified;
    if (modified && self.autoSave)
    {
        [self.deck saveToDisk];
    }
    if (modified && self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
}

-(void) saveToNrdb
{
    if (!Reachability.online)
    {
        [self showOfflineAlert];
        return;
    }

    [SVProgressHUD showWithStatus:l10n(@"Saving Deck...")];
    
    [[NRDB sharedInstance] saveDeck:self.deck completion:^(BOOL ok, NSString* deckId, NSString* msg) {
        // NSLog(@"saved ok=%d id=%@", ok, deckId);
        if (ok && deckId)
        {
            self.deck.netrunnerDbId = deckId;
            [self.deck saveToDisk];
        }
        [SVProgressHUD dismiss];
    }];
}

-(void) reImportDeckFromNetrunnerDb
{
    if (!Reachability.online)
    {
        [self showOfflineAlert];
        return;
    }
    
    NSAssert(self.deck.netrunnerDbId != nil, @"no nrdb deck id");
    [SVProgressHUD showWithStatus:l10n(@"Loading Deck...")];
    
    [[NRDB sharedInstance] loadDeck:self.deck.netrunnerDbId completion:^(Deck* deck) {
        if (deck == nil) {
            [UIAlertController alertWithTitle:nil message:l10n(@"Loading the deck from NetrunnerDB.com failed.") button:l10n(@"OK")];
        } else {
            deck.filename = self.deck.filename;
            self.deck = deck;
            self.deck.state = self.deck.state; // force .modified=YES
            
            [self refreshDeck];
        }
        
        [SVProgressHUD dismiss];
    }];
}

-(void) publishDeck
{
    if (!Reachability.online)
    {
        [self showOfflineAlert];
        return;
    }
    
    NSArray* errors = [self.deck checkValidity];
    if (errors.count == 0)
    {
        [SVProgressHUD showWithStatus:l10n(@"Publishing Deck...")];
        
        [[NRDB sharedInstance] publishDeck:self.deck completion:^(BOOL ok, NSString *deckId, NSString* errorMsg) {
            if (!ok)
            {
                NSString* failed = l10n(@"Publishing the deck at NetrunnerDB.com failed.");
                if (errorMsg.length > 0) {
                    failed = [NSString stringWithFormat:@"%@\n'%@'", failed, errorMsg];
                }
                [UIAlertController alertWithTitle:nil message:failed button:l10n(@"OK")];
            }
            if (ok && deckId)
            {
                NSString* msg = [NSString stringWithFormat:l10n(@"Deck published with ID %@"), deckId];
                [UIAlertController alertWithTitle:nil message:msg button:l10n(@"OK")];
            }
            
            [SVProgressHUD dismiss];
        }];
    }
    else
    {
        [UIAlertController alertWithTitle:nil message:l10n(@"Only valid decks can be published.") button:l10n(@"OK")];
    }
}

-(void) showOfflineAlert
{
    [UIAlertController alertWithTitle:nil
                         message:l10n(@"An Internet connection is required.")
                         button:l10n(@"OK")];
}

-(void) showCardList:(id)sender
{
    if (!self.listCards)
    {
        self.listCards = [[ListCardsViewController alloc] initWithNibName:@"ListCardsViewController" bundle:nil];
    }
    self.listCards.deck = self.deck;
    
    // protect against pushing the same controller twice (crashlytics #101)
    if (self.navigationController.topViewController != self.listCards)
    {
        [self.navigationController pushViewController:self.listCards animated:YES];
    }
}

-(void) refreshDeck
{
    TableData* data = [self.deck dataForTableView:self.sortType];
    self.cards = data.values;
    self.sections = data.sections;
    
    [self.tableView reloadData];

    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%ld %@", (long)self.deck.size, self.deck.size == 1 ? l10n(@"Card") : l10n(@"Cards")]];
    NSString* inf = self.deck.role == NRRoleCorp ? l10n(@"Inf") : l10n(@"Influence");
    if (self.deck.identity && !self.deck.isDraft)
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld/%ld %@", (long)self.deck.influence, (long)self.deck.influenceLimit, inf]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld %@", (long)self.deck.influence, inf]];
    }
    
    if (self.deck.role == NRRoleCorp)
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld %@", (long)self.deck.agendaPoints, l10n(@"AP")]];
    }
    
    [footer appendString:@"\n"];
    
    NSArray* reasons = [self.deck checkValidity];
    if (reasons.count > 0)
    {
        [footer appendString:reasons[0]];
    }

    self.statusLabel.text = footer;
    self.statusLabel.textColor = reasons.count == 0 ? self.view.tintColor : [UIColor redColor];
    
    self.drawButton.enabled = self.deck.size > 0;
    
    [self doAutoSave];
    [self setupNavigationButtons:self.deck.modified];
}

-(void) changeCount:(UIStepper*)stepper
{
    NSInteger section = stepper.tag / 1000;
    NSInteger row = stepper.tag - (section*1000);
    
    NSArray* arr = self.cards[section];
    CardCounter* cc = arr[row];
    
    NSInteger copies = stepper.value;
    NSInteger diff = ABS(cc.count - copies);
    if (copies < cc.count)
    {
        [self.deck addCard:cc.card copies:-diff];
    }
    else
    {
        [self.deck addCard:cc.card copies:diff];
    }
    
    [self doAutoSave];
    [self refreshDeck];
}

-(void) selectIdentity:(id)sender
{
    IphoneIdentityViewController* idvc = [[IphoneIdentityViewController alloc] initWithNibName:@"IphoneIdentityViewController" bundle:nil];
    idvc.role = self.deck.role;
    idvc.deck = self.deck;  
    [self.navigationController pushViewController:idvc animated:YES];
}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.cards[section];
    return arr.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* name = [self.sections objectAtIndex:section];
    NSArray* arr = self.cards[section];
    int cnt = 0;
    for (CardCounter* cc in arr)
    {
        if (!cc.isNull)
        {
            cnt += cc.count;
        }
    }
    
    if (section > 0 && cnt)
    {
        return [NSString stringWithFormat:@"%@ (%d)", name, cnt];
    }
    else
    {
        return name;
    }
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardCell";
    EditDeckCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.stepper.tag = indexPath.section * 1000 + indexPath.row;
    [cell.stepper addTarget:self action:@selector(changeCount:) forControlEvents:UIControlEventValueChanged];
    
    [cell.idButton setTitle:l10n(@"Identity") forState:UIControlStateNormal];
    [cell.idButton addTarget:self action:@selector(selectIdentity:) forControlEvents:UIControlEventTouchUpInside];
    
    CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
    
    if (cc.isNull)
    {
        // empty identity
        cell.nameLabel.textColor = [UIColor blackColor];
        cell.nameLabel.text = @"";
        cell.typeLabel.text = @"";
        cell.stepper.hidden = YES;
        cell.idButton.hidden = NO;
        cell.mwlLabel.hidden = YES;
        cell.influenceLabel.hidden = YES;
        return cell;
    }
    
    Card* card = cc.card;
    cell.stepper.minimumValue = 0;
    cell.stepper.maximumValue = card.maxPerDeck;
    cell.stepper.value = cc.count;
    cell.stepper.hidden = card.type == NRCardTypeIdentity;
    cell.idButton.hidden = card.type != NRCardTypeIdentity;
    
    if (card.unique)
    {
        cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@ •", (unsigned long)cc.count, card.name];
    }
    else
    {
        cell.nameLabel.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cc.count, card.name];
    }
    if (card.type == NRCardTypeIdentity)
    {
        cell.nameLabel.text = card.name;
        cell.stepper.hidden = YES;
        
        // show influence
        cell.influenceLabel.textColor = [UIColor blackColor];
        
        if (self.deck.isDraft) {
            cell.influenceLabel.text = @"∞";
        } else {
            NSInteger deckInfluence = self.deck.influenceLimit;
            NSString* inf = deckInfluence == -1 ? @"∞" : [NSString stringWithFormat:@"%ld", (long)deckInfluence];
            
            cell.influenceLabel.text = inf;
            if (deckInfluence != card.influenceLimit) {
                cell.influenceLabel.textColor = [UIColor redColor];
            }
        }
        
        // runners: show base link
        if (self.deck.role == NRRoleRunner) {
            cell.mwlLabel.text = [NSString stringWithFormat:@"%ld", (long)card.baseLink];
        } else {
            cell.mwlLabel.text = @"";
        }
    }
    
    cell.nameLabel.textColor = [UIColor blackColor];
    if (!self.deck.isDraft && card.owned < cc.count)
    {
        cell.nameLabel.textColor = [UIColor redColor];
    }
    
    cell.nameLabel.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightRegular];
    
    NSString* type = [Faction name:card.faction];;
    
    if (card.type != NRCardTypeIdentity) {
        NSInteger influence = [self.deck influenceFor:cc];
        if (influence > 0)
        {
            cell.influenceLabel.text = [NSString stringWithFormat:@"%ld", (long)influence];
            cell.influenceLabel.textColor = card.factionColor;
            cell.influenceLabel.hidden = NO;
        }
        else
        {
            cell.influenceLabel.text = @"";
            cell.influenceLabel.hidden = YES;
        }
        BOOL mwl = [card isMostWanted:self.deck.mwl];
        if (mwl) {
            cell.mwlLabel.text = [NSString stringWithFormat:@"%ld", (long)-cc.count];
        }
        cell.mwlLabel.hidden = !mwl;
    }
    
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        // type = [type stringByAppendingString:influenceStr];
        type = [type stringByAppendingString:@" · "];
        type = [type stringByAppendingString:card.subtype];
        cell.typeLabel.text = type;
    }
    else
    {
        // type = [type stringByAppendingString:influenceStr];
        cell.typeLabel.text = type;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
    
    if (cc.isNull)
    {
        return;
    }
    
    CardImageViewController* img = [[CardImageViewController alloc] initWithNibName:@"CardImageViewController" bundle:nil];
    img.cardCounters = [self.deck allCards];
    img.selectedCard = cc.card;
    
    [self.navigationController pushViewController:img animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
        
        if (!cc.isNull)
        {
            [self.deck addCard:cc.card copies:0];
        }
        
        [self performSelector:@selector(refreshDeck) withObject:nil afterDelay:0.0];
    }
}

-(NSString*) tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return l10n(@"Remove");
}

#pragma mark - legality

-(void) statusTapped:(UITapGestureRecognizer*)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Deck Legality") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Casual"), self.deck.mwl == NRMWLNone) handler:^(UIAlertAction * action) {
        self.deck.mwl = NRMWLNone;
        [self refreshDeck];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"MWL v1.0"), self.deck.mwl == NRMWLv1_0) handler:^(UIAlertAction * action) {
        self.deck.mwl = NRMWLv1_0;
        [self refreshDeck];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"MWL v1.1"), self.deck.mwl == NRMWLv1_1) handler:^(UIAlertAction * action) {
        self.deck.mwl = NRMWLv1_1;
        [self refreshDeck];
    }]];
    [alert addAction:[UIAlertAction cancelAction:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
