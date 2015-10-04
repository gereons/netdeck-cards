//
//  EditDeckViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>
#import <AFNetworkReachabilityManager.h>
#import <EXTScope.h>
#import "UIAlertAction+NetDeck.h"
#import "EditDeckViewController.h"
#import "ListCardsViewController.h"
#import "CardImageViewController.h"
#import "IphoneIdentityViewController.h"
#import "IphoneDrawSimulator.h"
#import "Deck.h"
#import "TableData.h"
#import "ImageCache.h"
#import "Faction.h"
#import "CardType.h"
#import "EditDeckCell.h"
#import "DeckExport.h"
#import "UIAlertAction+NetDeck.h"
#import "SettingsKeys.h"
#import "NRDB.h"
#import "DeckEmail.h"
#import "SVProgressHud.h"

@interface EditDeckViewController ()

@property BOOL autoSave;
@property BOOL autoSaveDropbox;
@property BOOL autoSaveNrdb;

@property NSArray* cards;
@property NSArray* sections;

@property UIButton* titleButton;  // used as the titleView in our navigation bar

@property ListCardsViewController* listCards;

@end

@implementation EditDeckViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EditDeckCell" bundle:nil] forCellReuseIdentifier:@"cardCell"];
    
    self.statusLabel.font = [UIFont md_systemFontOfSize:13];
    self.statusLabel.text = @"";
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    self.autoSave = [settings boolForKey:AUTO_SAVE];
    self.autoSaveDropbox = self.autoSave && [settings boolForKey:AUTO_SAVE_DB];
    self.autoSaveNrdb = [settings boolForKey:NRDB_AUTOSAVE];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSAssert(self.navigationController.viewControllers.count == 2, @"nav oops");
    
    // right buttons
    UIBarButtonItem* exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(exportDeck:)];
    UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(showCardList:)];
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItems = @[ addButton, exportButton ];

    self.titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.titleButton addTarget:self action:@selector(titleTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.titleButton.titleLabel.font = [UIFont md_mediumSystemFontOfSize:17];
    self.titleButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleButton.titleLabel.minimumScaleFactor = 0.5;
    
    [self setDeckName];
    topItem.titleView = self.titleButton;

    if (self.autoSave)
    {
        // make save button disappear
        self.saveButton.customView = [[UIView alloc] initWithFrame:CGRectZero];
        self.saveButton.enabled = NO;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USE_NRDB])
    {
        self.nrdbButton.customView = [[UIView alloc] initWithFrame:CGRectZero];
        self.nrdbButton.enabled = NO;
    }
    
    [self refreshDeck];
}

#pragma mark - deck name

-(void) setDeckName
{
    [self.titleButton setTitle:self.deck.name forState:UIControlStateNormal];
    [self.titleButton sizeToFit];
    
    self.title = self.deck.name;
    
    [self doAutoSave];
}

-(void) titleTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Enter Name") message:nil preferredStyle:UIAlertControllerStyleAlert];

    @weakify(self);
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        @strongify(self);
        textField.text = self.deck.name;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.returnKeyType = UIReturnKeyDone;
        textField.clearButtonMode = UITextFieldViewModeAlways;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction *action) {
        @strongify(self);
        UITextField* textField = alert.textFields.firstObject;
        self.deck.name = textField.text;
        [self setDeckName];
        self.saveButton.enabled = YES;
    }]];
    [alert addAction:[UIAlertAction cancelAction:nil]];
    
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - export 

-(void) exportDeck:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Export") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if ([settings boolForKey:USE_DROPBOX])
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"To Dropbox") handler:^(UIAlertAction *action) {
            [DeckExport asOctgn:self.deck autoSave:NO];
        }]];
    }
    
    if ([settings boolForKey:USE_NRDB])
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"To NetrunnerDB.com") handler:^(UIAlertAction *action) {
            [self saveToNrdb];
        }]];
    }
    
    if ([MFMailComposeViewController canSendMail])
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"As Email") handler:^(UIAlertAction *action) {
            [DeckEmail emailDeck:self.deck fromViewController:self];
        }]];
    }
    
    [alert addAction:[UIAlertAction cancelAction:nil]];
    
    [self presentViewController:alert animated:NO completion:nil];
}

-(void) drawClicked:(id)sender
{
    IphoneDrawSimulator* draw = [[IphoneDrawSimulator alloc] initWithNibName:@"IphoneDrawSimulator" bundle:nil];
    draw.deck = self.deck;
    [self.navigationController pushViewController:draw animated:YES];
}

#pragma mark - netrunnerdb.com

-(void) nrdbButtonClicked:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"NetrunnerDB.com" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.deck.netrunnerDbId.length)
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
    
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - save

-(void) saveClicked:(id)sender
{
    [self.deck saveToDisk];
    self.saveButton.enabled = NO;
    if (self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
    if (self.autoSaveNrdb && self.deck.netrunnerDbId && APP_ONLINE)
    {
        [self saveToNrdb];
    }
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
    if (!APP_ONLINE)
    {
        [self showOfflineAlert];
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Saving Deck...") maskType:SVProgressHUDMaskTypeBlack];
    
    [[NRDB sharedInstance] saveDeck:self.deck completion:^(BOOL ok, NSString* deckId) {
        // NSLog(@"saved ok=%d id=%@", ok, deckId);
        if (ok && deckId)
        {
            self.deck.netrunnerDbId = deckId;
            [self.deck saveToDisk];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [SVProgressHUD dismiss];
    }];
}

-(void) reImportDeckFromNetrunnerDb
{
    if (!APP_ONLINE)
    {
        [self showOfflineAlert];
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Loading Deck...") maskType:SVProgressHUDMaskTypeBlack];
    
    [[NRDB sharedInstance] loadDeck:self.deck completion:^(BOOL ok, Deck* deck) {
        if (!ok)
        {
            [SDCAlertView alertWithTitle:nil message:l10n(@"Loading the deck from NetrunnerDB.com failed.") buttons:@[l10n(@"OK")]];
        }
        else
        {
            deck.filename = self.deck.filename;
            self.deck = deck;
            self.deck.state = self.deck.state; // force .modified=YES
            
            [self refreshDeck];
        }
        
        [SVProgressHUD dismiss];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

-(void) publishDeck
{
    if (!APP_ONLINE)
    {
        [self showOfflineAlert];
        return;
    }
    
    NSArray* errors = [self.deck checkValidity];
    if (errors.count == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [SVProgressHUD showWithStatus:l10n(@"Publishing Deck...") maskType:SVProgressHUDMaskTypeBlack];
        
        [[NRDB sharedInstance] publishDeck:self.deck completion:^(BOOL ok, NSString *deckId) {
            if (!ok)
            {
                [SDCAlertView alertWithTitle:nil message:l10n(@"Publishing the deck at NetrunnerDB.com failed.") buttons:@[l10n(@"OK")]];
            }
            if (ok && deckId)
            {
                NSString* msg = [NSString stringWithFormat:l10n(@"Deck published with ID %@"), deckId];
                [SDCAlertView alertWithTitle:nil message:msg buttons:@[l10n(@"OK")]];
            }
            
            [SVProgressHUD dismiss];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }];
    }
    else
    {
        [SDCAlertView alertWithTitle:nil message:l10n(@"Only valid decks can be published.") buttons:@[ l10n(@"OK") ]];
    }
}

-(void) showOfflineAlert
{
    [SDCAlertView alertWithTitle:nil
                         message:l10n(@"An Internet connection is required.")
                         buttons:@[l10n(@"OK")]];
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
    TableData* data = [self.deck dataForTableView:NRDeckSortType];
    self.cards = data.values;
    self.sections = data.sections;
    
    [self.tableView reloadData];

    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%d %@", self.deck.size, self.deck.size == 1 ? l10n(@"Card") : l10n(@"Cards")]];
    NSString* inf = self.deck.role == NRRoleCorp ? l10n(@"Inf") : l10n(@"Influence");
    if (self.deck.identity && !self.deck.isDraft)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d/%d %@", self.deck.influence, self.deck.identity.influenceLimit, inf]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %d %@", self.deck.influence, inf]];
    }
    
    if (self.deck.role == NRRoleCorp)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d %@", self.deck.agendaPoints, l10n(@"AP")]];
    }
    
    [footer appendString:@"\n"];
    
    NSArray* reasons = [self.deck checkValidity];
    if (reasons.count > 0)
    {
        [footer appendString:reasons[0]];
    }

    self.statusLabel.text = footer;
    self.statusLabel.textColor = reasons.count == 0 ? [UIColor darkGrayColor] : [UIColor redColor];
    
    self.saveButton.enabled = self.deck.modified;
    self.drawButton.enabled = self.deck.size > 0;
    
    [self doAutoSave];
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

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) // no count for identities
    {
        return self.sections[section];
    }
    
    NSArray* arr = self.cards[section];
    return [NSString stringWithFormat:@"%@ (%ld)", self.sections[section], (long)arr.count];
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
    
    if (ISNULL(cc))
    {
        // empty identity
        cell.nameLabel.textColor = [UIColor blackColor];
        cell.nameLabel.text = @"";
        cell.typeLabel.text = @"";
        cell.stepper.hidden = YES;
        cell.idButton.hidden = NO;
        return cell;
    }
    
    Card* card = cc.card;
    cell.stepper.minimumValue = 0;
    cell.stepper.maximumValue = card.maxPerDeck;
    cell.stepper.value = cc.count;
    cell.stepper.hidden = card.type == NRCardTypeIdentity;
    cell.idButton.hidden = card.type != NRCardTypeIdentity;
    
//    cell.nameLabel.backgroundColor = [UIColor redColor];
//    cell.typeLabel.backgroundColor = [UIColor greenColor];
//    cell.influenceLabel.backgroundColor = [UIColor blueColor];

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
    }
    
    cell.nameLabel.textColor = [UIColor blackColor];
    if (card.isCore && !self.deck.isDraft)
    {
        if (card.owned < cc.count)
        {
            cell.nameLabel.textColor = [UIColor redColor];
        }
    }
    
    cell.nameLabel.font = [UIFont md_systemFontOfSize:16];
    
    NSString* type = [Faction name:card.faction];;
    NSString* influenceStr = @"";
    
    NSInteger influence = [self.deck influenceFor:cc];
    if (influence > 0)
    {
        influenceStr = [NSString stringWithFormat:@" · %ld %@", (long)influence, l10n(@"Influence")];
        
        cell.influenceLabel.text = [NSString stringWithFormat:@"%ld", (long)influence];
        cell.influenceLabel.textColor = card.factionColor;
    }
    else
    {
        cell.influenceLabel.text = @"";
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
    
    if (ISNULL(cc))
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
        
        if (!ISNULL(cc))
        {
            [self.deck addCard:cc.card copies:0];
        }
        
        [self performSelector:@selector(refreshDeck) withObject:nil afterDelay:0.001];
    }
}

#pragma mark - Deck Editor

-(BOOL) deckModified
{
    // only answer truthfully if we're the current top viewcontroller
    UIViewController* topVC = self.navigationController.viewControllers.lastObject;
    if (topVC == self)
    {
        return self.deck.modified;
    }
    return NO;
}

-(void) saveDeck
{
    [self.deck saveToDisk];
}

@end
