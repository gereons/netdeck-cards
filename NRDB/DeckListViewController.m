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
#import "DeckImport.h"

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

@property NSString* filename;
@property BOOL autoSaveDropbox;
@property CGFloat normalTableHeight;

@property CGFloat scale;
@property BOOL largeCells;
@property UIAlertView* nameAlert;
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
        self.deck.name = [NSString stringWithFormat:@"Deck #%ld", (long)seq];
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
    topItem.title = @"Deck";
    
    NSArray* selections = @[
        [UIImage imageNamed:@"tableviewicon"],
        [UIImage imageNamed:@"cardviewicon"],
        [UIImage imageNamed:@"listviewicon"]
    ];
    UISegmentedControl* viewSelector = [[UISegmentedControl alloc] initWithItems:selections];
    viewSelector.selectedSegmentIndex = 0;
    [viewSelector addTarget:self action:@selector(toggleView:) forControlEvents:UIControlEventValueChanged];
    self.toggleViewButton = [[UIBarButtonItem alloc] initWithCustomView:viewSelector];
    
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveDeck:)];
    topItem.leftBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Identity" style:UIBarButtonItemStylePlain target:self action:@selector(selectIdentity:)],
        [[UIBarButtonItem alloc] initWithTitle:@"Name" style:UIBarButtonItemStylePlain target:self action:@selector(enterName:)],
        self.saveButton,
        self.toggleViewButton
    ];
    self.saveButton.enabled = NO;
    
    topItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"] style:UIBarButtonItemStylePlain target:self action:@selector(exportDeck:)],
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"743-printer"] style:UIBarButtonItemStylePlain target:self action:@selector(printDeck:)],
    ];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(identitySelected:) name:SELECT_IDENTITY object:nil];
    [nc addObserver:self selector:@selector(deckChanged:) name:DECK_CHANGED object:nil];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];

    [self.deckNameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterName:)]];
    self.deckNameLabel.userInteractionEnabled = YES;
    
    self.tableView.hidden = NO;
    self.collectionView.hidden = YES;
    
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

#pragma mark keyboard show/hide

#define KEYBOARD_HEIGHT_OFFSET  225

-(void) willShowKeyboard:(NSNotification*)sender
{
    self.normalTableHeight = self.tableView.frame.size.height;
    
    CGRect kbRect = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float kbHeight = kbRect.size.width; // kbRect is screen/portrait coords
    float tableHeight = self.normalTableHeight - kbHeight + 44;
    self.tableView.frame = CGRectSetHeight(self.tableView.frame, tableHeight);
}

-(void) willHideKeyboard:(NSNotification*)sender
{
   self.tableView.frame = CGRectSetHeight(self.tableView.frame, self.normalTableHeight);
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
    self.saveButton.enabled = NO;
    
    if (self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
}

#pragma mark deck name

-(void) enterName:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Enter Name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField* textField = [alert textFieldAtIndex:0];
    textField.placeholder = @"Enter Deck Name";
    textField.text = self.deck.name;
    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    textField.clearButtonMode = UITextFieldViewModeAlways;
    textField.returnKeyType = UIReturnKeyDone;
    textField.delegate = self;
    
    self.nameAlert = alert;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        self.deck.name = [alertView textFieldAtIndex:0].text;
        self.deckNameLabel.text = self.deck.name;
        self.deckChanged = YES;
        [self refresh];
    }
    self.nameAlert = nil;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.nameAlert dismissWithClickedButtonIndex:1 animated:NO];
    [textField resignFirstResponder];
    return NO;
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
    }
}

-(void) toggleView:(UISegmentedControl*)sender
{
    TF_CHECKPOINT(@"toggle deck view");
    self.tableView.hidden = sender.selectedSegmentIndex == 1;
    self.collectionView.hidden = sender.selectedSegmentIndex != 1;
    
    self.largeCells = sender.selectedSegmentIndex == 0;
    
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
    
    NSArray* reasons = [self.deck checkValidity];
    if (reasons.count > 0)
    {
        [footer appendString:@" · "];
        [footer appendString:reasons[0]];
    }
    self.footerLabel.textColor = reasons.count == 0 ? [UIColor darkGrayColor] : [UIColor redColor];
    
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
    self.deckChanged = YES;
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

-(NSString*) tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
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
    CGRect rect = CGRectMake(cell.center.x, cell.center.y-86, 1, 1); // 86 is half the height of a CardImagePopup
    [CardImagePopup showForCard:cc fromRect:rect inView:self.collectionView];
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardImageCell";
    
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
            int influence = [self.deck influenceFor:cc];
            if (influence > 0)
            {
                cell.copiesLabel.text = [NSString stringWithFormat:@"×%d · %d Influence", cc.count, influence];
            }
            else
            {
                cell.copiesLabel.text = [NSString stringWithFormat:@"×%d", cc.count];
            }
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
