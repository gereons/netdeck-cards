//
//  EditDeckViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 09.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#warning handle nrdb autosave

#import "UIAlertAction+NRDB.h"
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
#import "UIAlertAction+NRDB.h"
#import "SettingsKeys.h"

@interface EditDeckViewController ()

@property BOOL autoSave;
@property BOOL autoSaveDropbox;

@property NSArray* cards;
@property NSArray* sections;

@property UILabel* titleLabel;  // used as the titleView in out navigation bar

@end

@implementation EditDeckViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EditDeckCell" bundle:nil] forCellReuseIdentifier:@"cardCell"];
    
    self.statusLabel.text = @"";
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    self.autoSave = [settings boolForKey:AUTO_SAVE];
    self.autoSaveDropbox = self.autoSave && [settings boolForKey:AUTO_SAVE_DB];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // right buttons
    UIBarButtonItem* exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(exportDeck:)];
    UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addCard:)];
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.rightBarButtonItems = @[ addButton, exportButton ];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textColor = self.view.tintColor;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.5;
    [self setDeckName];
    topItem.titleView = self.titleLabel;
    
    UITapGestureRecognizer* titleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleTapped:)];
    titleTap.numberOfTapsRequired = 1;
    self.titleLabel.userInteractionEnabled = YES;
    [self.titleLabel addGestureRecognizer:titleTap];
    
    if (self.autoSave)
    {
        // make save button disappear
        self.saveButton.customView = [[UIView alloc] initWithFrame:CGRectZero];
        self.saveButton.enabled = NO;
    }
    
    [self refreshDeck:@(YES)];
}

#pragma mark - deck name

-(void) setDeckName
{
    self.titleLabel.text = self.deck.name;
    CGSize maxSize = [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    self.titleLabel.frame = CGRectMake(0,0, maxSize.width, 500);
    
    self.title = self.deck.name;
    
    [self doAutoSave];
}

-(void) titleTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Enter Name") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.deck.name;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction *action) {
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
            NSLog(@"stub - save to nrdb");
        }]];
    }
    
    if ([MFMailComposeViewController canSendMail])
    {
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"As Email") handler:^(UIAlertAction *action) {
            [self sendAsEmail];
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
}

-(void) doAutoSave
{
    if (self.autoSave)
    {
        [self.deck saveToDisk];
    }
    if (self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
}

-(void) addCard:(id)sender
{
    ListCardsViewController* listCards = [[ListCardsViewController alloc] initWithNibName:@"ListCardsViewController" bundle:nil];
    listCards.deck = self.deck;
    [self.navigationController pushViewController:listCards animated:YES];
}

-(void) refreshDeck:(NSNumber*)reload
{
    TableData* data = [self.deck dataForTableView:NRDeckSortType];
    self.cards = data.values;
    self.sections = data.sections;
    
    if (reload.boolValue)
    {
        [self.tableView reloadData];
    }
    
    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%d %@", self.deck.size, self.deck.size == 1 ? l10n(@"Card") : l10n(@"Cards")]];
    if (self.deck.identity && !self.deck.isDraft)
    {
        [footer appendString:[NSString stringWithFormat:@" · %d/%d %@", self.deck.influence, self.deck.identity.influenceLimit, l10n(@"Influence")]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %d %@", self.deck.influence, l10n(@"Influence")]];
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
    [self refreshDeck:@(YES)];
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
    return self.sections[section];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardCell";
    EditDeckCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.stepper.tag = indexPath.section * 1000 + indexPath.row;
    [cell.stepper addTarget:self action:@selector(changeCount:) forControlEvents:UIControlEventValueChanged];

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
    
    [cell.idButton addTarget:self action:@selector(selectIdentity:) forControlEvents:UIControlEventTouchUpInside];
    
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
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        cell.typeLabel.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
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
    NSMutableArray* cards = [NSMutableArray array];
    
    for (CardCounter* cc in [self.deck allCards])
    {
        [cards addObject:cc.card];
    }
    img.cards = cards;
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
        
        [self performSelector:@selector(refreshDeck:) withObject:@(YES) afterDelay:0.001];
    }
}

#pragma mark email

-(void) sendAsEmail
{
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    
    if (mailer)
    {
        mailer.mailComposeDelegate = self;
        NSString *emailBody = [DeckExport asPlaintextString:self.deck];
        [mailer setMessageBody:emailBody isHTML:NO];
        
        [mailer setSubject:self.deck.name];
        
        [self presentViewController:mailer animated:NO completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:NO completion:nil];
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
