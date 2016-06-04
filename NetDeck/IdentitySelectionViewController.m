//
//  IdentitySelectionViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 26.12.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "IdentitySelectionViewController.h"
#import "IdentityViewCell.h"
#import "CardImageViewPopover.h"

#import "CGRectUtils.h"
#import "IdentityCardView.h"
#import "IdentitySectionHeaderView.h"

@interface IdentitySelectionViewController ()

@property NRRole role;

@property NSArray* factions;
@property NSArray* factionNames;
@property NSMutableArray* identities;
@property Card* initialIdentity;
@property Card* selectedIdentity;
@property NSIndexPath* selectedIndexPath;
@property NRFaction selectedFaction;
@property BOOL viewTable;

@end

@implementation IdentitySelectionViewController

+(void) showForRole:(NRRole)role inViewController:(UIViewController*)vc withIdentity:(Card*)card
{
    IdentitySelectionViewController* isvc = [[IdentitySelectionViewController alloc] initWithRole:role andIdentity:card];

    [vc presentViewController:isvc animated:NO completion:nil];
}

- (id)initWithRole:(NRRole)role andIdentity:(Card*)identity
{
    self = [super initWithNibName:@"IdentitySelectionViewController" bundle:nil];
    if (self)
    {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.role = role;
        self.initialIdentity = identity;
        self.selectedIdentity = identity;
        self.selectedFaction = NRFactionNone;
        self.viewTable = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.IDENTITY_TABLE];
        
        [self initIdentities];
    }
    return self;
}

-(void) dealloc
{
    NSAssert(self.collectionView.window == nil, @"collectionView.window still set");
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = l10n(@"Choose Identity");
    [self.okButton setTitle:l10n(@"Done") forState:UIControlStateNormal];
    [self.cancelButton setTitle:l10n(@"Cancel") forState:UIControlStateNormal];
    
    // setup tableview
    UINib* nib = [UINib nibWithNibName:@"IdentityViewCellSubtitle" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"identityCell"];
    
    UITapGestureRecognizer* tableTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tableTap.numberOfTapsRequired = 2;
    [self.tableView addGestureRecognizer:tableTap];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // setup collectionview
    [self.collectionView registerNib:[UINib nibWithNibName:@"IdentityCardView" bundle:nil] forCellWithReuseIdentifier:@"cardThumb"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"IdentitySectionHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeader"];
    
    UITapGestureRecognizer* collectionTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    collectionTap.numberOfTapsRequired = 2;
    [self.collectionView addGestureRecognizer:collectionTap];
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    layout.headerReferenceSize = CGSizeMake(500, 22);
    layout.sectionInset = UIEdgeInsetsMake(2, 2, 0, 2);
    layout.minimumInteritemSpacing = 3;
    layout.minimumLineSpacing = 3;
    
    self.tableView.hidden = !self.viewTable;
    self.collectionView.hidden = self.viewTable;
    self.modeSelector.selectedSegmentIndex = self.viewTable;
    
    CGPoint oldCenter = self.factionSelector.center;
    
    BOOL includeDraft = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_DRAFT];
    BOOL dataDestinyAllowed = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_DATA_DESTINY];
    
    if (self.role == NRRoleRunner)
    {
        [self.factionSelector removeSegmentAtIndex:5 animated:NO];
        
        [self.factionSelector setTitle:l10n(@"All") forSegmentAtIndex:0];
        [self.factionSelector setTitle:[Faction name:NRFactionAnarch] forSegmentAtIndex:1];
        [self.factionSelector setTitle:[Faction name:NRFactionCriminal] forSegmentAtIndex:2];
        [self.factionSelector setTitle:[Faction name:NRFactionShaper] forSegmentAtIndex:3];
        if (includeDraft)
        {
            // [self.factionSelector setTitle:[Faction name:NRFactionNeutral] forSegmentAtIndex:4];
            [self.factionSelector setTitle:l10n(@"Draft") forSegmentAtIndex:4];
        }
        else
        {
            [self.factionSelector removeSegmentAtIndex:4 animated:NO];
        }
        
        if (dataDestinyAllowed)
        {
            [self.factionSelector insertSegmentWithTitle:[Faction name:NRFactionAdam] atIndex:4 animated:NO];
            [self.factionSelector insertSegmentWithTitle:[Faction name:NRFactionApex] atIndex:5 animated:NO];
            [self.factionSelector insertSegmentWithTitle:[Faction shortName:NRFactionSunnyLebeau] atIndex:6 animated:NO];

            self.factionSelectorWidth.constant += 100;
        }
    }
    else
    {
        [self.factionSelector setTitle:l10n(@"All") forSegmentAtIndex:0];
        [self.factionSelector setTitle:[Faction shortName:NRFactionHaasBioroid] forSegmentAtIndex:1];
        [self.factionSelector setTitle:[Faction shortName:NRFactionNBN] forSegmentAtIndex:2];
        [self.factionSelector setTitle:[Faction shortName:NRFactionJinteki] forSegmentAtIndex:3];
        [self.factionSelector setTitle:[Faction shortName:NRFactionWeyland] forSegmentAtIndex:4];

        if (includeDraft)
        {
            // [self.factionSelector setTitle:[Faction name:NRFactionNeutral] forSegmentAtIndex:5];
            [self.factionSelector setTitle:l10n(@"Draft") forSegmentAtIndex:5];
        }
        else
        {
            [self.factionSelector removeSegmentAtIndex:5 animated:NO];
        }
    }
    self.factionSelector.center = oldCenter;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.selectedIndexPath)
    {
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
}

- (void)initIdentities
{
    BOOL useDraft = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_DRAFT];
    NSMutableArray* factions;
    
    if (self.selectedFaction == NRFactionNone)
    {
        factions = [[Faction factionsForRole:self.role] mutableCopy];
        
        // remove entries for "none" and "neutral"
        [factions removeObject:[Faction name:NRFactionNone]];

        // move 'neutral' to the end
        NSString* neutral = [Faction name:NRFactionNeutral];
        [factions removeObject:neutral];
        if (useDraft)
        {
            [factions addObject:neutral];
        }
    }
    else
    {
        factions = [NSMutableArray array];
        [factions addObject:[Faction name:self.selectedFaction]];
    }
    
    self.identities = [NSMutableArray array];
    self.factionNames = [NSArray arrayWithArray:factions];
    
    self.selectedIndexPath = nil;
    NSSet* disabledPackCodes = [PackManager disabledPackCodes];
    
    NSArray* identities = [CardManager identitiesForRole:self.role];
    for (int i=0; i<factions.count; ++i)
    {
        [self.identities addObject:[NSMutableArray array]];
        
        for (int j=0; j<identities.count; ++j)
        {
            Card* card = identities[j];
            if ([disabledPackCodes containsObject:card.packCode])
            {
                continue;
            }
            if (self.selectedFaction != NRFactionNone && card.faction != self.selectedFaction)
            {
                continue;
            }
            
            if ([[factions objectAtIndex:i] isEqualToString:[Faction name:card.faction]])
            {
                NSMutableArray* arr = self.identities[i];
                [arr addObject:card];
                
                if ([self.selectedIdentity isEqual:card])
                {
                    self.selectedIndexPath = [NSIndexPath indexPathForRow:arr.count-1 inSection:i];
                }
            }
        }
    }
    
    if (useDraft)
    {
        // rename "Neutral" section to "Draft"
        NSMutableArray* tmp = self.factionNames.mutableCopy;
        [tmp removeLastObject];
        [tmp addObject:l10n(@"Draft")];
        self.factionNames = tmp;
    }
    
    NSAssert(self.identities.count == self.factionNames.count, @"count mismatch");
}

#pragma mark buttons

-(void) okClicked:(id)sender
{
    if (self.selectedIdentity)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.SELECT_IDENTITY object:self userInfo:@{ @"code": self.selectedIdentity.code }];
    }
    [self cancelClicked:sender];
}

-(void) cancelClicked:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark double-tap handler

-(void) doubleTap:(UITapGestureRecognizer*)sender
{
    if (UIGestureRecognizerStateEnded != sender.state)
    {
        return;
    }
    
    if (!self.viewTable)
    {
        NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:[sender locationInView:self.collectionView]];
        
        Card* card = [self.identities objectAtIndexPath:indexPath];
        if (card != nil)
        {
            self.selectedIdentity = card;
            self.selectedIndexPath = indexPath;
        }
    }
    [self okClicked:nil];
}

-(void)viewModeChange:(UISegmentedControl*)sender
{
    self.viewTable = sender.selectedSegmentIndex;
    self.tableView.hidden = !self.viewTable;
    self.collectionView.hidden = self.viewTable;
    [[NSUserDefaults standardUserDefaults] setBool:self.viewTable forKey:SettingsKeys.IDENTITY_TABLE];
    
    if (self.selectedIndexPath)
    {
        [self.tableView reloadData];
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        
        [self.collectionView reloadData];
        [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
}

-(void) factionChange:(UISegmentedControl*)sender
{
    BOOL dataDestinyAllowed = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_DATA_DESTINY];
    NRFaction faction4 = dataDestinyAllowed ? NRFactionAdam : NRFactionNeutral;

    switch (sender.selectedSegmentIndex)
    {
        case 0:
            self.selectedFaction = NRFactionNone;
            break;
        case 1:
            self.selectedFaction = self.role == NRRoleRunner ? NRFactionAnarch : NRFactionHaasBioroid;
            break;
        case 2:
            self.selectedFaction = self.role == NRRoleRunner ? NRFactionCriminal : NRFactionNBN;
            break;
        case 3:
            self.selectedFaction = self.role == NRRoleRunner ? NRFactionShaper : NRFactionJinteki;
            break;
        case 4:
            self.selectedFaction = self.role == NRRoleRunner ? faction4 : NRFactionWeyland;
            break;
        case 5:
            self.selectedFaction = self.role == NRRoleRunner ? NRFactionApex : NRFactionNeutral;
            break;
        case 6:
            NSAssert(self.role == NRRoleRunner, @"role mismatch");
            self.selectedFaction = NRFactionSunnyLebeau;
            break;
        case 7:
            NSAssert(self.role == NRRoleRunner, @"role mismatch");
            self.selectedFaction = NRFactionNeutral;
            break;
    }
    
    [self initIdentities];
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

-(void) showImage:(UIButton*)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    Card* card = [self.identities objectAtIndexPath:indexPath];
    if (card == nil)
    {
        return;
    }
    
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    rect.origin.x = sender.frame.origin.x;
    [CardImageViewPopover showForCard:card fromRect:rect inViewController:self subView:self.tableView];
}

#pragma mark table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.identities.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.identities[section];
    return arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"identityCell";
    
    IdentityViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell)
    {
        cell = [[IdentityViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    [cell.infoButton addTarget:self action:@selector(showImage:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    Card* card = [self.identities objectAtIndexPath:indexPath];
    
    if ([card isEqual:self.selectedIdentity])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.selected = YES;
        self.selectedIndexPath = indexPath;
    }
    
    cell.titleLabel.text = card.name;
    cell.titleLabel.textColor = card.factionColor;
    
    cell.deckSizeLabel.text = [@(card.minimumDecksize) stringValue];
    
    if (card.influenceLimit == -1)
    {
        cell.influenceLimitLabel.text = @"∞";
    }
    else
    {
        cell.influenceLimitLabel.text = [@(card.influenceLimit) stringValue];
    }
    
    if (self.role == NRRoleRunner)
    {
        cell.linkLabel.text = [NSString stringWithFormat:@"%ld", (long)card.baseLink];
        cell.linkIcon.hidden = NO;
    }
    else
    {
        cell.linkLabel.text = @"";
        cell.linkIcon.hidden = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedIndexPath)
    {
        UITableViewCell* prevCell = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
        prevCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    Card* card = [self.identities objectAtIndexPath:indexPath];
    
    self.selectedIdentity = card;
    self.selectedIndexPath = indexPath;
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.factionNames[section];
}

#pragma mark collectionview

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardThumb";
    Card* card = [self.identities objectAtIndexPath:indexPath];
    
    IdentityCardView* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.card = card;
    [cell.selectButton addTarget:self action:@selector(selectCell:) forControlEvents:UIControlEventTouchUpInside];
    
    NSInteger tag = (indexPath.section * 1000) + indexPath.row;
    cell.selectButton.tag = tag;
    
    if (self.selectedIndexPath && [self.selectedIndexPath compare:indexPath] == NSOrderedSame)
    {
        cell.layer.borderWidth = 4;
        cell.layer.borderColor = [card.factionColor CGColor];
        cell.layer.cornerRadius = 8;
    }
    else
    {
        cell.layer.borderWidth = 0;
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Card* card = [self.identities objectAtIndexPath:indexPath];
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];

    // convert to on-screen coordinates
    CGRect rect = [collectionView convertRect:cell.frame toView:self.collectionView];

    [CardImageViewPopover showForCard:card fromRect:rect inViewController:self subView:self.collectionView];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(160, 148);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 0, 2);
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.identities.count;
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray* arr = self.identities[section];
    return arr.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    IdentitySectionHeaderView* header = nil;
    if (kind == UICollectionElementKindSectionHeader)
    {
        header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeader" forIndexPath:indexPath];
        header.titleLabel.text = self.factionNames[indexPath.section];
        
        Card* card = [self.identities objectAtIndexPath:indexPath];
        if (card != nil)
        {
            header.titleLabel.textColor = card.factionColor;
        }
        else
        {
            header.titleLabel.textColor = [UIColor blackColor];
        }
    }
    
    NSAssert(header != nil, @"no header?");
    return header;
}

#pragma mark select cell

-(void) selectCell:(UIButton*)sender
{
    // NSLog(@"select cell %d", sender.tag);
    NSInteger section = sender.tag / 1000;
    NSInteger item = sender.tag - (1000 * section);
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:item inSection:section];
    
    Card* card = [self.identities objectAtIndexPath:indexPath];
    if (card != nil)
    {
        self.selectedIdentity = card;
        self.selectedIndexPath = indexPath;
    }
    
    [self.collectionView reloadData];
}

@end
