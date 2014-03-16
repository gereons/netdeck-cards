//
//  DeckListViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 08.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <SVProgressHUD.h>

#import "DeckListViewController.h"
#import "CardImageViewPopover.h"
#import "IdentitySelectionViewController.h"
#import "DeckAnalysisViewController.h"
#import "DrawSimulatorViewController.h"
#import "CardImagePopup.h"
#import "ImageCache.h"

#import "Deck.h"
#import "DeckManager.h"
#import "CardCounter.h"
#import "Card.h"
#import "Faction.h"
#import "CardType.h"
#import "DeckExport.h"
#import "DeckImport.h"
#import "CardSets.h"

#import "CardCell.h"
#import "CardImageCell.h"
#import "CGRectUtils.h"
#import "Notifications.h"
#import "SettingsKeys.h"

@interface DeckListViewController ()

@property (strong) NSArray* sections;
@property (strong) NSArray* cards;

@property UIActionSheet* actionSheet;
@property UIPrintInteractionController* printController;
@property UIBarButtonItem* toggleViewButton;
@property UIBarButtonItem* saveButton;
@property UIBarButtonItem* exportButton;

@property NSString* filename;
@property BOOL autoSaveDropbox;

@property CGFloat scale;
@property BOOL largeCells;
@property UIAlertView* nameAlert;

@end

@implementation DeckListViewController

enum { CARD_VIEW, TABLE_VIEW, LIST_VIEW };
enum { NAME_ALERT = 1, SWITCH_ALERT };

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
    
    self.scale = 1.0;
    
    if (self.filename)
    {
        self.deck = [DeckManager loadDeckFromPath:self.filename];
        self.deckNameLabel.text = self.deck.name;
    }
    
    if (self.deck == nil)
    {
        self.deck = [Deck new];
        self.deck.role = self.role;
    }
    
    if (self.deck.filename == nil)
    {
        NSInteger seq = [[NSUserDefaults standardUserDefaults] integerForKey:FILE_SEQ] + 1;
        if (self.deck.name == nil)
        {
            self.deck.name = [NSString stringWithFormat:@"Deck #%ld", (long)seq];
        }
        self.deckNameLabel.text = self.deck.name;
    }
    
    [self initCards];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"LargeCardCell" bundle:nil] forCellReuseIdentifier:@"largeCardCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SmallCardCell" bundle:nil] forCellReuseIdentifier:@"smallCardCell"];
    self.largeCells = YES;
    [self refresh];
    
    UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    // topItem.title = @"Deck";
    
    NSArray* selections = @[
        [UIImage imageNamed:@"cardviewicon"],   // CARD_VIEW
        [UIImage imageNamed:@"tableviewicon"],  // TABLE_VIEW
        [UIImage imageNamed:@"listviewicon"]    // LIST_VIEW
    ];
    UISegmentedControl* viewSelector = [[UISegmentedControl alloc] initWithItems:selections];
    viewSelector.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DECK_VIEW_STYLE];
    [viewSelector addTarget:self action:@selector(toggleView:) forControlEvents:UIControlEventValueChanged];
    self.toggleViewButton = [[UIBarButtonItem alloc] initWithCustomView:viewSelector];
    [self doToggleView:viewSelector.selectedSegmentIndex];
    
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Save") style:UIBarButtonItemStylePlain target:self action:@selector(saveDeck:)];
    topItem.leftBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:l10n(@"Identity") style:UIBarButtonItemStylePlain target:self action:@selector(selectIdentity:)],
        [[UIBarButtonItem alloc] initWithTitle:l10n(@"Name") style:UIBarButtonItemStylePlain target:self action:@selector(enterName:)],
        self.saveButton,
        [[UIBarButtonItem alloc] initWithTitle:l10n(@"Duplicate") style:UIBarButtonItemStylePlain target:self action:@selector(duplicateDeck:)],
        self.toggleViewButton
    ];
    self.saveButton.enabled = NO;
    
    self.exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"] style:UIBarButtonItemStylePlain target:self action:@selector(exportDeck:)];
    topItem.rightBarButtonItem = self.exportButton;

    [self.drawButton setTitle:l10n(@"Draw") forState:UIControlStateNormal];
    [self.analysisButton setTitle:l10n(@"Analysis") forState:UIControlStateNormal];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(identitySelected:) name:SELECT_IDENTITY object:nil];
    [nc addObserver:self selector:@selector(deckChanged:) name:DECK_CHANGED object:nil];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];

    [self.deckNameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterName:)]];
    self.deckNameLabel.userInteractionEnabled = YES;
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    self.autoSaveDropbox = [settings boolForKey:USE_DROPBOX] && [settings boolForKey:AUTO_SAVE_DB];
    self.deckChanged = NO;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardImageCell" bundle:nil] forCellWithReuseIdentifier:@"cardImageCell"];
    
    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [self.collectionView addGestureRecognizer:pinch];

    if (self.deck.identity == nil && self.filename == nil)
    {
        [self selectIdentity:nil];
    }
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.deck.cards.count > 0)
    {
        // so that FilteredCardViewController gets a chance to reload
        [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:nil];
    }
}

#pragma mark keyboard show/hide

#define KEYBOARD_HEIGHT_OFFSET  225

-(void) willShowKeyboard:(NSNotification*)sender
{
    CGRect kbRect = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float kbHeight = kbRect.size.width; // kbRect is screen/portrait coords

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64.0, 0.0, kbHeight-44, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

-(void) willHideKeyboard:(NSNotification*)sender
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64.0, 0.0, 0.0, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
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
    
    self.deckChanged = NO;
    if (sender != nil)
    {
        [SVProgressHUD showSuccessWithStatus:l10n(@"Saving...")];
    }
    if (self.deck.filename)
    {
        [DeckManager saveDeck:self.deck toPath:self.deck.filename];
    }
    else
    {
        self.deck.filename = [DeckManager saveDeck:self.deck];
    }
    self.saveButton.enabled = NO;
    
    if (self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
}

-(void) analysisClicked:(id)sender
{
    [DeckAnalysisViewController showForDeck:self.deck inViewController:self];
}

-(void) drawSimulatorClicked:(id)sender
{
    [DrawSimulatorViewController showForDeck:self.deck inViewController:self];
}

#pragma mark duplicate deck

-(void) duplicateDeck:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"Duplicate this deck?")
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:l10n(@"No")
                                          otherButtonTitles:l10n(@"Yes, switch to copy"), l10n(@"Yes, but stay here"), nil];
    alert.tag = SWITCH_ALERT;
    [alert show];
}

#pragma mark deck name

-(void) enterName:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"Enter Name") message:nil delegate:self cancelButtonTitle:l10n(@"Cancel") otherButtonTitles:@"OK", nil];
    alert.tag = NAME_ALERT;
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
    
    if (alertView.tag == NAME_ALERT)
    {
        self.deck.name = [alertView textFieldAtIndex:0].text;
        self.deckNameLabel.text = self.deck.name;
        self.deckChanged = YES;
        [self refresh];
        
        self.nameAlert = nil;
    }
    else if (alertView.tag == SWITCH_ALERT)
    {
        Deck* newDeck = [self.deck duplicate];

        [DeckManager saveDeck:newDeck];
        if (self.autoSaveDropbox)
        {
            if (newDeck.identity && newDeck.cards.count > 0)
            {
                [DeckExport asOctgn:newDeck autoSave:YES];
            }
        }

        if (buttonIndex == 1)
        {
            self.deck = newDeck;
            [self refresh];
        }
    }
    else
    {
        NSAssert(NO, @"this can't happen");
    }
}


#pragma mark identity selection

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
    
    self.deckChanged = YES;
    [self refresh];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_SAVE])
    {
        [self saveDeck:nil];
    }
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
    
    [self.actionSheet addButtonWithTitle:l10n(@"Dropbox: OCTGN")];
    [self.actionSheet addButtonWithTitle:l10n(@"Dropbox: BBCode")];
    [self.actionSheet addButtonWithTitle:l10n(@"Dropbox: Markdown")];
    [self.actionSheet addButtonWithTitle:l10n(@"Dropbox: Plain Text")];
    
    [self.actionSheet addButtonWithTitle:l10n(@"Clipboard: BBCode")];
    [self.actionSheet addButtonWithTitle:l10n(@"Clipboard: Markdown")];
    [self.actionSheet addButtonWithTitle:l10n(@"Clipboard: Plain Text")];
    
    [self.actionSheet addButtonWithTitle:l10n(@"Print")];
    
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:l10n(@"Connect to your Dropbox account first.") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    
    TF_CHECKPOINT(@"export deck");
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    switch (buttonIndex)
    {
        case 0: // octgn
            if (self.deck.identity == nil)
            {
                [[[UIAlertView alloc] initWithTitle:nil message:l10n(@"Deck needs to have an Identity.") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                return;
            }
            if (self.deck.cards.count == 0)
            {
                [[[UIAlertView alloc] initWithTitle:nil message:l10n(@"Deck needs to have Cards.") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
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
            [DeckImport updateCount];
            break;
        case 5: // markdown
            pasteboard.string = [DeckExport asMarkdownString:self.deck];
            [DeckImport updateCount];
            break;
        case 6: // plain text
            pasteboard.string = [DeckExport asPlaintextString:self.deck];
            [DeckImport updateCount];
            break;
        case 7: // print
            [self printDeck:self.exportButton];
    }
}

-(void) toggleView:(UISegmentedControl*)sender
{
    TF_CHECKPOINT(@"toggle deck view");
    
    NSInteger viewMode = sender.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:DECK_VIEW_STYLE];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self doToggleView:viewMode];
}

-(void) doToggleView:(NSInteger)viewMode
{
    self.tableView.hidden = viewMode == CARD_VIEW;
    self.collectionView.hidden = viewMode != CARD_VIEW;
    
    self.largeCells = viewMode == TABLE_VIEW;
    
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
    self.deckChanged = YES;
    [self refresh];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_SAVE])
    {
        [self saveDeck:nil];
    }
}

-(void) refresh
{
    [self initCards];
    [self reloadViews];
    
    if (self.deckChanged)
    {
        self.saveButton.enabled = YES;
    }
    
    self.drawButton.enabled = self.deck.cards.count > 0;
    self.analysisButton.enabled = self.deck.cards.count > 0;
    
    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%d %@", self.deck.size, self.deck.size == 1 ? l10n(@"Card") : l10n(@"Cards")]];
    if (self.deck.identity)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d/%d %@", self.deck.influence, self.deck.identity.influenceLimit, l10n(@"Influence")]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %d %@", self.deck.influence, l10n(@"Influence")]];
    }
    
    if (self.role == NRRoleCorp)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d %@", self.deck.agendaPoints, l10n(@"Agenda Points")]];
    }
    
    NSArray* reasons = [self.deck checkValidity];
    if (reasons.count > 0)
    {
        [footer appendString:@" · "];
        [footer appendString:reasons[0]];
    }
    
    self.footerLabel.textColor = reasons.count == 0 ? [UIColor darkGrayColor] : [UIColor redColor];
    self.footerLabel.text = footer;
    
    NSString* set = [CardSets mostRecentSetUsedInDeck:self.deck];
    if (set)
    {
        self.lastSetLabel.text = [NSString stringWithFormat:l10n(@"Cards up to %@"), set];
    }
    
    self.deckNameLabel.text = self.deck.name;
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
    self.deckChanged = YES;
    [self refresh];

    NSIndexPath* indexPath;
    int i=0;
    for (int section = 0; indexPath == nil && section < self.cards.count; ++section)
    {
        NSArray* arr = self.cards[section];
        for (int row = 0; row < arr.count; ++row)
        {
            CardCounter* cc = arr[row];
            
            if ([card isEqual:cc.card])
            {
                if (self.tableView.hidden)
                {
                    indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                }
                else
                {
                    indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                }
                break;
            }
            ++i;
        }
    }
    NSAssert(indexPath != nil, @"added card not found!?");
    
    if (!self.tableView.hidden)
    {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self performSelector:@selector(flashTableCell:) withObject:indexPath afterDelay:0.01];
    }
    if (!self.collectionView.hidden)
    {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        [self performSelector:@selector(flashImageCell:) withObject:indexPath afterDelay:0.01];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_SAVE])
    {
        [self saveDeck:nil];
    }
}

-(void) flashTableCell:(NSIndexPath*)indexPath
{
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

-(void) flashImageCell:(NSIndexPath*)indexPath
{
    CardImageCell* cell = (CardImageCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^void() {
                         cell.transform = CGAffineTransformMakeScale(1.05, 1.05);
                     }
                     completion:^(BOOL finished) {
                         cell.transform = CGAffineTransformIdentity;
                     }];
}

#pragma mark Table View

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.largeCells ? 83 : 40;
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
    if (self.largeCells)
    {
        NSString* name = [self.sections objectAtIndex:section];
        NSArray* arr = self.cards[section];
        int cnt = 0;
        for (CardCounter* cc in arr)
        {
            cnt += cc.count;
        }
        
        return [NSString stringWithFormat:@"%@ (%d)", name, cnt];
    }
    else
    {
        return nil;
    }
}

- (CardCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = self.largeCells ? @"largeCardCell" : @"smallCardCell";
    CardCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.separatorInset = UIEdgeInsetsZero;
    
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    
    cell.deck = self.deck;
    cell.cardCounter = cc;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSArray* arr = self.cards[indexPath.section];
        CardCounter* cc = arr[indexPath.row];
        
        if (cc.card.type == NRCardTypeIdentity)
        {
            self.deck.identity = nil;
        }
        else
        {
            [self.deck removeCard:cc.card];
        }
        
        self.deckChanged = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:nil];
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* arr = self.cards[indexPath.section];
    CardCounter* cc = arr[indexPath.row];
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    
    [CardImageViewPopover showForCard:cc.card fromRect:rect inView:self.tableView];
}

-(NSString*) tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return l10n(@"Remove");
}

#pragma mark collectionview

#define CARD_WIDTH  225
#define CARD_HEIGHT 333

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CARD_WIDTH * self.scale, CARD_HEIGHT * self.scale);
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
        cc = [CardCounter initWithCard:self.deck.identity];
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

    // convert to on-screen coordinates
    CGRect rect = [collectionView convertRect:cell.frame toView:collectionView.superview];

    BOOL topVisible = rect.origin.y >= 66;
    BOOL bottomVisible = rect.origin.y + rect.size.height <= 728;
    // NSLog(@"%@ %d %d", NSStringFromCGRect(rect), topVisible, bottomVisible);
    
    static const int POPUP_HEIGHT = 170; // full height (including the arrow) of the popup
    static const int LABEL_HEIGHT = 20; // height of the label underneath the image
    
    UIPopoverArrowDirection direction = UIPopoverArrowDirectionAny;

    CGRect popupOrigin = CGRectMake(cell.center.x, cell.frame.origin.y, 1, 1);
    if (topVisible && bottomVisible)
    {
        // fully visible, show from top of image
        direction = UIPopoverArrowDirectionUp;
    }
    else if (topVisible)
    {
        if (rect.origin.y < 728 - POPUP_HEIGHT)
        {
            // top Visible and enough space - show from top of image
            direction = UIPopoverArrowDirectionUp;
        }
        else
        {
            // top visible, not enough space - show above image
            direction = UIPopoverArrowDirectionDown;
        }
    }
    else if (bottomVisible)
    {
        popupOrigin.origin.y += cell.frame.size.height - LABEL_HEIGHT;
        if (rect.origin.y + rect.size.height >= 66 + POPUP_HEIGHT)
        {
            // bottom visible and enough space - show from bottom
            direction = UIPopoverArrowDirectionDown;
        }
        else
        {
            // bottom visible, not enough space - show below image
            direction = UIPopoverArrowDirectionUp;
        }
    }
    else
    {
        NSAssert(NO, @"selected invisible cell?!");
    }
    
    CardImagePopup* cip = [CardImagePopup showForCard:cc fromRect:popupOrigin inView:self.collectionView direction:direction];
    cip.cell = cell;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardImageCell";
    
    CardImageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil)
    {
        cell = [[CardImageCell alloc] init];
    }
    
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
            int influence = [self.deck influenceFor:cc];
            if (influence > 0)
            {
                cell.copiesLabel.text = [NSString stringWithFormat:@"×%d · %d %@", cc.count, influence, l10n(@"Influence")];
            }
            else
            {
                cell.copiesLabel.text = [NSString stringWithFormat:@"×%d", cc.count];
            }
        }
        
        cell.copiesLabel.textColor = [UIColor blackColor];
        if ([card.setCode isEqualToString:@"core"])
        {
            NSInteger cores = [[NSUserDefaults standardUserDefaults] integerForKey:NUM_CORES];
            NSInteger owned = cores * card.quantity;
            
            if (owned < cc.count)
            {
                cell.copiesLabel.textColor = [UIColor redColor];
            }
        }
    }
    
    if (![cell.card isEqual:card])
    {
        cell.imageView.image = nil;
    }
    cell.card = card;
    
    [cell loadImage:card];
    
    return cell;
}

-(void) pinchGesture:(UIPinchGestureRecognizer*)gesture
{
    static CGFloat scaleStart;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        scaleStart = self.scale;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        self.scale = scaleStart * gesture.scale;
    }
    self.scale = MAX(self.scale, 0.5);
    self.scale = MIN(self.scale, 1.0);
    
    [self.collectionView.collectionViewLayout invalidateLayout];
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
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:l10n(@"Printing Problem") message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
