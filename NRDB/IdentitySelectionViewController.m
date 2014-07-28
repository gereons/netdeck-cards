//
//  IdentitySelectionViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 26.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <CSStickyHeaderFlowLayout.h>

#import "IdentitySelectionViewController.h"
#import "IdentityViewCell.h"
#import "CardImageViewPopover.h"

#import "Faction.h"
#import "Card.h"
#import "CardManager.h"
#import "CardSets.h"
#import "CGRectUtils.h"
#import "Notifications.h"
#import "SettingsKeys.h"
#import "CardThumbView.h"
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

@end

@implementation IdentitySelectionViewController

static NSInteger viewMode = 1;

+(void) showForRole:(NRRole)role inViewController:(UIViewController*)vc withIdentity:(Card*)card
{
    IdentitySelectionViewController* isvc = [[IdentitySelectionViewController alloc] initWithRole:role andIdentity:card];

    [vc presentViewController:isvc animated:NO completion:nil];
}

- (id)initWithRole:(NRRole)role andIdentity:(Card*)identity
{
    TF_CHECKPOINT(@"identity selection");
    
    self = [super initWithNibName:@"IdentitySelectionViewController" bundle:nil];
    if (self)
    {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.role = role;
        self.initialIdentity = identity;
        self.selectedIdentity = identity;
        self.selectedFaction = NRFactionNone;
        
        [self initIdentities];
    }
    return self;
}

- (void)initIdentities
{
    NSMutableArray* factions;
    
    if (self.selectedFaction == NRFactionNone)
    {
        factions = [[Faction factionsForRole:self.role] mutableCopy];
        
        // remove entry for "none"
        [factions removeObject:[Faction name:NRFactionNone]];
        
        // move 'neutral' to the end
        NSString* neutral = [Faction name:NRFactionNeutral];
        [factions removeObject:neutral];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:USE_DRAFT_IDS])
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
    
    NSSet* disabledSets = [CardSets disabledSetCodes];
    
    NSArray* identities = [CardManager identitiesForRole:self.role];
    for (int i=0; i<factions.count; ++i)
    {
        [self.identities addObject:[NSMutableArray array]];
        
        for (int j=0; j<identities.count; ++j)
        {
            Card* card = identities[j];
            if ([disabledSets containsObject:card.setCode])
            {
                continue;
            }
            if (self.selectedFaction != NRFactionNone && card.faction != self.selectedFaction)
            {
                continue;
            }
            
            if ([[factions objectAtIndex:i] isEqualToString:card.factionStr])
            {
                NSMutableArray* arr = self.identities[i];
                [arr addObject:card];
                
                if ([self.initialIdentity isEqual:card])
                {
                    self.selectedIndexPath = [NSIndexPath indexPathForRow:arr.count-1 inSection:i];
                }
            }
        }
    }
    
    NSAssert(self.identities.count == self.factionNames.count, @"count mismatch");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = l10n(@"Choose Identity");
    [self.okButton setTitle:l10n(@"Done") forState:UIControlStateNormal];
    [self.cancelButton setTitle:l10n(@"Cancel") forState:UIControlStateNormal];
    
    // Do any additional setup after loading the view from its nib.
    UINib* nib = [UINib nibWithNibName:@"IdentityViewCellSubtitle" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"identityCell"];
    
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.tableView addGestureRecognizer:doubleTap];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardThumbView" bundle:nil] forCellWithReuseIdentifier:@"cardThumb"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"IdentitySectionHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeader"];
    
    CSStickyHeaderFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.headerReferenceSize = CGSizeMake(500, 22);
    layout.sectionInset = UIEdgeInsetsMake(2, 2, 0, 2);
    layout.minimumInteritemSpacing = 3;
    layout.minimumLineSpacing = 3;
    
    self.tableView.hidden = viewMode == 0;
    self.collectionView.hidden = viewMode == 1;
    self.modeSelector.selectedSegmentIndex = viewMode;
    
    CGPoint oldCenter = self.factionSelector.center;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USE_DRAFT_IDS])
    {
        [self.factionSelector removeSegmentAtIndex:5 animated:NO];
    }
    else
    {
        [self.factionSelector setTitle:l10n(@"Neutral") forSegmentAtIndex:5];
    }
    
    if (self.role == NRRoleRunner)
    {
        [self.factionSelector removeSegmentAtIndex:4 animated:NO];
        [self.factionSelector setTitle:l10n(@"All") forSegmentAtIndex:0];
        [self.factionSelector setTitle:[Faction name:NRFactionAnarch] forSegmentAtIndex:1];
        [self.factionSelector setTitle:[Faction name:NRFactionCriminal] forSegmentAtIndex:2];
        [self.factionSelector setTitle:[Faction name:NRFactionShaper] forSegmentAtIndex:3];
    }
    else
    {
        [self.factionSelector setTitle:l10n(@"All") forSegmentAtIndex:0];
        [self.factionSelector setTitle:l10n(@"H-B") forSegmentAtIndex:1];
        [self.factionSelector setTitle:l10n(@"NBN") forSegmentAtIndex:2];
        [self.factionSelector setTitle:l10n(@"Jinteki") forSegmentAtIndex:3];
        [self.factionSelector setTitle:l10n(@"Weyland") forSegmentAtIndex:4];
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

-(void) okClicked:(id)sender
{
    if (self.selectedIdentity)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SELECT_IDENTITY object:self userInfo:@{ @"code": self.selectedIdentity.code }];
    }
    [self cancelClicked:sender];
}

-(void) cancelClicked:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void) doubleTap:(UITapGestureRecognizer*)sender
{
    if (UIGestureRecognizerStateEnded == sender.state)
    {
        [self okClicked:nil];
    }
}

-(void)viewModeChange:(UISegmentedControl*)sender
{
    viewMode = sender.selectedSegmentIndex;
    self.tableView.hidden = viewMode == 0;
    self.collectionView.hidden = viewMode == 1;
    
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
    NSLog(@"select faction %d", sender.selectedSegmentIndex);
    
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
            self.selectedFaction = self.role == NRRoleRunner ? NRFactionNeutral : NRFactionWeyland;
            break;
        case 5:
            NSAssert(self.role == NRRoleCorp, @"role mismatch");
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
    
    NSArray* arr = self.identities[indexPath.section];
    Card* card = arr[indexPath.row];
    
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    rect.origin.x = sender.frame.origin.x;
    [CardImageViewPopover showForCard:card fromRect:rect inView:self.tableView];
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
    
    NSArray* arr = self.identities[indexPath.section];
    Card* c = arr[indexPath.row];
    
    if ([c isEqual:self.selectedIdentity])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.selected = YES;
        self.selectedIndexPath = indexPath;
    }
    
    cell.titleLabel.text = c.name;
    cell.titleLabel.textColor = c.factionColor;
    
    cell.deckSizeLabel.text = [@(c.minimumDecksize) stringValue];
    
    if (c.influenceLimit == -1)
    {
        cell.influenceLimitLabel.text = @"∞";
    }
    else
    {
        cell.influenceLimitLabel.text = [@(c.influenceLimit) stringValue];
    }
    
    if (self.role == NRRoleRunner)
    {
        cell.linkLabel.text = [NSString stringWithFormat:@"%d", c.baseLink];
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
    
    NSMutableArray* arr = self.identities[indexPath.section];
    Card* c = arr[indexPath.row];
    
    self.selectedIdentity = c;
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
    NSArray* arr = self.identities[indexPath.section];
    Card* card = arr[indexPath.row];
    
    CardThumbView* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.card = card;
    
    if (cell.selected)
    {
        cell.layer.borderWidth = 5;
        cell.layer.borderColor = [card.factionColor CGColor];
        cell.layer.cornerRadius = 8;
    }
    else
    {
        cell.layer.borderWidth = 0;
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.layer.borderWidth = 0;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* arr = self.identities[indexPath.section];
    Card* card = arr[indexPath.row];
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];

    cell.layer.borderWidth = 5;
    cell.layer.borderColor = [card.factionColor CGColor];
    cell.layer.cornerRadius = 8;
    
    // convert to on-screen coordinates
    CGRect rect = [collectionView convertRect:cell.frame toView:self.collectionView];

    if ([self.selectedIdentity isEqual:card])
    {
        [CardImageViewPopover showForCard:card fromRect:rect inView:self.collectionView];
    }
    
    self.selectedIdentity = card;
    self.selectedIndexPath = indexPath;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(160, 119);
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
        NSArray* arr = self.identities[indexPath.section];
        Card* card = arr[0];
        header.titleLabel.textColor = card.factionColor;
    }
    
    return header;
}

@end
