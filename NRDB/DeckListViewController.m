//
//  DeckListViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 08.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <SVProgressHUD.h>

#import "DeckListViewController.h"
#import "CardImageViewPopover.h"
#import "IdentitySelectionViewController.h"
#import "CardImagePopup.h"
#import "ImageCache.h"

#import "Deck.h"
#import "DeckManager.h"
#import "CardCounter.h"
#import "Card.h"
#import "Faction.h"
#import "CardType.h"
#import "DeckExport.h"

#import "CardCell.h"
#import "CardImageCell.h"
#import "CGRectUtils.h"
#import "Notifications.h"
#import "SettingsKeys.h"

@interface DeckListViewController ()

@property (strong) Deck* deck;
@property (strong) NSArray* sections;
@property (strong) NSArray* cards;

@property UIActionSheet* actionSheet;
@property UIPrintInteractionController* printController;
@property UIBarButtonItem* toggleViewButton;

@property NSString* filename;
@property BOOL autoSaveDropbox;

@end

@implementation DeckListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.filename)
    {
        self.deck = [DeckManager loadDeckFromPath:self.filename];
        self.deckNameLabel.text = self.deck.name;
    }
    
    if (self.deck == nil)
    {
        NSInteger seq = [[NSUserDefaults standardUserDefaults] integerForKey:FILE_SEQ] + 1;
        self.deck = [Deck new];
        self.deck.role = self.role;
        self.deck.name = [NSString stringWithFormat:@"Deck #%ld", (long)seq];
        self.deckNameLabel.text = self.deck.name;
    }
    
    [self initCards];
    [self refresh];
    
    UINib* nib = [UINib nibWithNibName:@"CardCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cardCell"];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:HOLD_FOR_IMAGE])
    {
        UIGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [self.tableView addGestureRecognizer:longPress];
    }
    
    UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.title = @"Deck";
    
    self.toggleViewButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"705-photos"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleView:)];
    
    topItem.leftBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Identity" style:UIBarButtonItemStylePlain target:self action:@selector(selectIdentity:)],
        [[UIBarButtonItem alloc] initWithTitle:@"Name" style:UIBarButtonItemStylePlain target:self action:@selector(enterName:)],
        [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveDeck:)],
        self.toggleViewButton
    ];
    
    topItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"] style:UIBarButtonItemStylePlain target:self action:@selector(exportDeck:)],
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"743-printer"] style:UIBarButtonItemStylePlain target:self action:@selector(printDeck:)],
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(identitySelected:) name:SELECT_IDENTITY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deckChanged:) name:DECK_CHANGED object:nil];
    
    [self.deckNameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterName:)]];
    self.deckNameLabel.userInteractionEnabled = YES;
    
    self.tableView.hidden = NO;
    self.collectionView.hidden = YES;
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    self.autoSaveDropbox = [settings boolForKey:USE_DROPBOX] && [settings boolForKey:AUTO_SAVE_DB];
    
    nib = [UINib nibWithNibName:@"CardImageCell" bundle:nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"cardCell"];
    
    if (self.deck.identity == nil && self.filename == nil)
    {
        [self selectIdentity:nil];
    }
}

-(void) loadDeckFromFile:(NSString *)filename
{
    self.filename = filename;
}

-(void) saveDeck:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    if (sender != nil)
    {
        [SVProgressHUD showSuccessWithStatus:@"Saving..."];
    }
    if (self.deck.filename)
    {
        [DeckManager saveDeck:self.deck toPath:self.deck.filename];
    }
    else
    {
        self.deck.filename = [DeckManager saveDeck:self.deck];
    }
    
    if (self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
}

-(void) enterName:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Enter Name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].placeholder = @"Enter Deck Name";
    [alert textFieldAtIndex:0].text = self.deck.name;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        self.deck.name = [alertView textFieldAtIndex:0].text;
        self.deckNameLabel.text = self.deck.name;
    }
}

-(void) selectIdentity:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    Card* identity = self.deck.identity;
    [IdentitySelectionViewController showForRole:self.role inViewController:self withIdentity:identity];
}

-(void) identitySelected:(NSNotification*)sender
{
    NSString* code = [sender.userInfo objectForKey:@"code"];
    self.deck.identity = [Card cardByCode:code];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_SAVE])
    {
        [self saveDeck:nil];
    }
    [self refresh];
}

-(void) exportDeck:(UIBarButtonItem*)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    if (self.printController)
    {
        [self dismissPrintController];
        return;
    }
    
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [self.actionSheet addButtonWithTitle:@"Dropbox: OCTGN"];
    [self.actionSheet addButtonWithTitle:@"Dropbox: BBCode"];
    [self.actionSheet addButtonWithTitle:@"Dropbox: Markdown"];
    [self.actionSheet addButtonWithTitle:@"Dropbox: Plain text"];
    
    [self.actionSheet addButtonWithTitle:@"Clipboard: BBCode"];
    [self.actionSheet addButtonWithTitle:@"Clipboard: Markdown"];
    [self.actionSheet addButtonWithTitle:@"Clipboard: Plain text"];
    
    self.actionSheet.cancelButtonIndex = [self.actionSheet addButtonWithTitle:@""];

    [self.actionSheet showFromBarButtonItem:sender animated:NO];
}

-(void) dismissActionSheet
{
    [self.actionSheet dismissWithClickedButtonIndex:-1 animated:NO];
    self.actionSheet = nil;
}

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.actionSheet = nil;
    if (buttonIndex == -1 || buttonIndex == actionSheet.cancelButtonIndex)
    {
        return;
    }
    
    if (buttonIndex < 4 && ![[NSUserDefaults standardUserDefaults] boolForKey:USE_DROPBOX])
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"Connect to your Dropbox account first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    
    TF_CHECKPOINT(@"export deck");
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    switch (buttonIndex)
    {
        case 0: // octgn
            if (self.deck.identity == nil)
            {
                [[[UIAlertView alloc] initWithTitle:nil message:@"Deck needs to have an Identity." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                return;
            }
            if (self.deck.cards.count == 0)
            {
                [[[UIAlertView alloc] initWithTitle:nil message:@"Deck needs to have Cards." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                return;
            }
            [DeckExport asOctgn:self.deck autoSave:NO];
            break;
        case 1: // bbcode
            [DeckExport asBBCode:self.deck];
            break;
        case 2: // markdown
            [DeckExport asMarkdown:self.deck];
            break;
        case 3: // plain text
            [DeckExport asPlaintext:self.deck];
            break;
    
        case 4: // bbcode
            pasteboard.string = [DeckExport asBBCodeString:self.deck];
            break;
        case 5: // markdown
            pasteboard.string = [DeckExport asMarkdownString:self.deck];
            break;
        case 6: // plain text
            pasteboard.string = [DeckExport asPlaintextString:self.deck];
            break;
    }
}

-(void) toggleView:(id)sender
{
    TF_CHECKPOINT(@"toggle deck view");
    self.tableView.hidden = !self.tableView.hidden;
    self.collectionView.hidden = !self.collectionView.hidden;
    
    NSString* img = self.tableView.hidden ? @"854-list" : @"705-photos";
    self.toggleViewButton.image = [UIImage imageNamed:img];
    
    [self reloadViews];
}

-(void) reloadViews
{
    if (!self.tableView.hidden)
    {
        [self.tableView reloadData];
    }
    
    if (!self.collectionView.hidden)
    {
        [self.collectionView reloadData];
    }
}

#pragma mark notifications

-(void) deckChanged:(NSNotification*)sender
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_SAVE])
    {
        [self saveDeck:nil];
    }
    
    [self refresh];
}

-(void) refresh
{
    [self initCards];
    [self reloadViews];
    
    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%d %@", self.deck.size, self.deck.size == 1 ? @"Card" : @"Cards"]];
    if (self.deck.identity)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d/%d Influence", self.deck.influence, self.deck.identity.influenceLimit]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %d Influence", self.deck.influence]];
    }
    
    if (self.role == NRRoleCorp)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d Agenda Points", self.deck.agendaPoints]];
    }
    
    NSString* reason;
    BOOL valid = [self.deck valid:&reason];
    if (!valid)
    {
        [footer appendString:@" · "];
        [footer appendString:reason];
    }
    self.footerLabel.textColor = valid ? [UIColor darkGrayColor] : [UIColor redColor];
    
    self.footerLabel.text = footer;
}

-(void) initCards
{
    TableData* data = [self.deck dataForTableView];
    self.cards = data.values;
    self.sections = data.sections;
}

-(void) addCard:(Card *)card
{
    [self.deck addCard:card copies:1];
    [self refresh];
    
    int section, row;
    NSIndexPath* indexPath;
    for (section = 0; indexPath == nil && section < self.cards.count; ++section)
    {
        NSArray* arr = self.cards[section];
        for (row = 0; row < arr.count; ++row)
        {
            CardCounter* cc = arr[row];
            
            if ([card isEqual:cc.card])
            {
                indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                break;
            }
        }
    }
    NSAssert(indexPath != nil, @"added card not found!?");
    
    if (!self.tableView.hidden)
    {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        
        CardCell* cell = (CardCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^void() {
                             cell.backgroundColor = [UIColor lightGrayColor];
                         }
                         completion:^(BOOL finished) {
                             cell.backgroundColor = [UIColor whiteColor];
                         }];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_SAVE])
    {
        [self saveDeck:nil];
    }
}

#pragma mark Table View

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 83;
    
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    return 50 + cc.card.attributedTextHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
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
    return [self.sections objectAtIndex:section];
}

- (CardCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardCell";
    CardCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil)
    {
        cell = [[CardCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.separatorInset = UIEdgeInsetsZero;
    
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    
    cell.cardCounter = cc;
    cell.tag = indexPath.section;
    
    Card* card = cc.card;
    
    if (card.unique)
    {
        cell.name.text = [NSString stringWithFormat:@"%@ •", card.name];
    }
    else
    {
        cell.name.text = card.name;
    }
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        cell.type.text = [NSString stringWithFormat:@"%@ %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        cell.type.text = [NSString stringWithFormat:@"%@ %@", factionName, typeName];
    }
    
    // NSAttributedString* ability = card.attributedText
    // cell.descr.frame = CGRectSetSize(cell.descr.frame, 417, card.attributedTextHeight);
    // cell.descr.attributedText = ability;
    
    cell.influence.textColor = card.factionColor;
    int influence = [self.deck influenceFor:cc];
    if (cell.cardCounter.card.type == NRCardTypeAgenda)
    {
        cell.influence.text = [NSString stringWithFormat:@"%d", card.agendaPoints * cc.count];
    }
    else if (influence > 0)
    {
        cell.influence.text = [NSString stringWithFormat:@"%d", influence];
    }
    else
    {
        cell.influence.text = @"";
    }

    cell.influence.hidden = card.type == NRCardTypeIdentity;
    cell.copiesLabel.hidden = card.type == NRCardTypeIdentity;
    cell.copiesStepper.hidden = card.type == NRCardTypeIdentity;
    
    // labels from top: cost/strength/mu
    switch (card.type)
    {
        case NRCardTypeIdentity:
            cell.cost.text = [@(card.minimumDecksize) stringValue];
            cell.strength.text = [@(card.influenceLimit) stringValue];
            if (card.role == NRRoleRunner)
            {
                cell.mu.text = [NSString stringWithFormat:@"%d Link", card.baseLink];
            }
            else
            {
                cell.mu.text = @"";
            }
            break;

        case NRCardTypeProgram:
        case NRCardTypeResource:
        case NRCardTypeEvent:
        case NRCardTypeHardware:
        case NRCardTypeIce:
            cell.cost.text = card.cost != -1 ? [NSString stringWithFormat:@"%d Cr", card.cost] : @"";
            cell.strength.text = card.strength != -1 ? [NSString stringWithFormat:@"%d Str", card.strength] : @"";
            cell.mu.text = card.mu != -1 ? [NSString stringWithFormat:@"%d Str", card.mu] : @"";
            break;

        case NRCardTypeAgenda:
            cell.cost.text = [NSString stringWithFormat:@"%d Adv", card.advancementCost];
            cell.strength.text = [NSString stringWithFormat:@"%d AP", card.agendaPoints];
            cell.mu.text = @"";
            break;
            
        case NRCardTypeAsset:
        case NRCardTypeOperation:
        case NRCardTypeUpgrade:
            cell.cost.text = card.cost != -1 ? [NSString stringWithFormat:@"%d Cr", card.cost] : @"";
            cell.strength.text = card.trash != -1 ? [NSString stringWithFormat:@"%d Tr", card.trash] : @"";
            cell.mu.text = @"";
            break;
            
        case NRCardTypeNone:
            NSAssert(NO, @"this can't happen");
            break;
    }
    
    cell.copiesStepper.value = cc.count;
    // cell.copiesLabel.text = [NSString stringWithFormat:@"%d %@", cc.count, cc.count == 1 ? @"Copy" : @"Copies"];
    cell.copiesLabel.text = [NSString stringWithFormat:@"×%d", cc.count];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSArray* arr = self.cards[indexPath.section];
        CardCounter* cc = arr[indexPath.row];
        [self.deck removeCard:cc.card];
        
        [self refresh];
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    
    [CardImageViewPopover showForCard:cc.card fromRect:rect inView:self.tableView];
}

-(void) longPress:(UIGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [gesture locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath != nil)
        {
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        [CardImageViewPopover dismiss];
    }
}

#pragma mark collectionview

#define CARD_WIDTH  225
#define CARD_HEIGHT 333

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CARD_WIDTH, CARD_HEIGHT);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 2, 2);
}


-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.deck.cards.count;
    if (self.deck.identity)
        ++count;
    return count;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    CardCounter* cc;
    if (self.deck.identity && index == 0)
    {
        return;
    }
    else
    {
        if (self.deck.identity)
        {
            --index;
        }
        
        cc = self.deck.cards[index];
    }
    
    // NSLog(@"selected %@", cc.card.name);
    CardImageCell* cell = (CardImageCell*)[collectionView cellForItemAtIndexPath:indexPath];
    CGRect rect = CGRectMake(cell.center.x, cell.center.y-100, 1, 1);
    [CardImagePopup showForCard:cc fromRect:rect inView:self.collectionView];
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardCell";
    
    CardImageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil)
    {
        cell = [[CardImageCell alloc] init];
    }
    
    cell.backgroundColor = [UIColor whiteColor];
    
    NSInteger index = indexPath.row;
    Card* card;
    if (self.deck.identity && index == 0)
    {
        card = self.deck.identity;
        cell.copiesLabel.text = @"";
    }
    else
    {
        if (self.deck.identity)
        {
            --index;
        }
        
        CardCounter* cc = self.deck.cards[index];
        card = cc.card;
        
        if (card.type == NRCardTypeAgenda)
        {
            cell.copiesLabel.text = [NSString stringWithFormat:@"×%d · %d AP", cc.count, cc.count*cc.card.agendaPoints];
        }
        else
        {
            cell.copiesLabel.text = [NSString stringWithFormat:@"×%d · %d Influence", cc.count, cc.count*cc.card.influence];
        }
    }
    
    [cell.activityIndicator startAnimating];
    [[ImageCache sharedInstance] getImageFor:card
                                     success:^(Card* card, UIImage* img) {
                                         [cell.activityIndicator stopAnimating];
                                         cell.imageView.image = img;
                                     }
                                     failure:^(Card* card, NSInteger statusCode) {
                                         [cell.activityIndicator stopAnimating];
                                     }];

    return cell;
}

#pragma mark printing

-(void) dismissPrintController
{
    [self.printController dismissAnimated:NO];
    self.printController = nil;
}

-(void) printDeck:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    self.printController = [UIPrintInteractionController sharedPrintController];
    self.printController.delegate = self;
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = self.deck.name;
    self.printController.printInfo = printInfo;
    
    UISimpleTextPrintFormatter *formatter = [[UISimpleTextPrintFormatter alloc] initWithText:[DeckExport asPlaintextString:self.deck]];
    formatter.startPage = 0;
    formatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
    self.printController.printFormatter = formatter;
    self.printController.showsPageRange = YES;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error)
    {
        if (!completed && error)
        {
            // NSLog(@"Printing could not complete because of error: %@", error);
            NSString* msg = error.localizedDescription;
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Printing Problem", nil) message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    };
    
    [self.printController presentFromBarButtonItem:sender animated:NO completionHandler:completionHandler];
}

-(void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController
{
    self.printController = nil;
}


@end
