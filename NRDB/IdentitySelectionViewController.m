//
//  IdentitySelectionViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 26.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "IdentitySelectionViewController.h"
#import "IdentityViewCell.h"
#import "CardImageViewPopover.h"

#import "Faction.h"
#import "Card.h"
#import "CardSets.h"
#import "CGRectUtils.h"
#import "Notifications.h"
#import "SettingsKeys.h"

@interface IdentitySelectionViewController ()

@property NRRole role;

@property NSArray* factionNames;
@property NSMutableArray* identities;
@property Card* selectedIdentity;
@property NSIndexPath* selectedIndexPath;

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
        self.selectedIdentity = identity;
        self.factionNames = [NSMutableArray array];
        self.identities = [NSMutableArray array];
        
        NSMutableArray* factions = [[Faction factionsForRole:role] mutableCopy];
        
        [factions removeObject:[Faction name:NRFactionNeutral]];
        [factions removeObject:[Faction name:NRFactionNone]];
        
        self.factionNames = [NSArray arrayWithArray:factions];
        
        NSSet* disabledSets = [CardSets disabledSetCodes];
        
        NSArray* identities = [Card identitiesForRole:role];
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
                
                if ([[factions objectAtIndex:i] isEqualToString:card.factionStr])
                {
                    NSMutableArray* arr = self.identities[i];
                    [arr addObject:card];
                
                    if ([identity isEqual:card])
                    {
                        self.selectedIndexPath = [NSIndexPath indexPathForRow:arr.count-1 inSection:i];
                    }
                }
            }
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UINib* nib = [UINib nibWithNibName:@"IdentityViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"identityCell"];
    
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.tableView addGestureRecognizer:doubleTap];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.selectedIndexPath)
    {
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
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

#pragma mark table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.identities.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray* arr = self.identities[section];
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
    
    NSMutableArray* arr = self.identities[indexPath.section];
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
    cell.influenceLimitLabel.text = [@(c.influenceLimit) stringValue];
    
    if (self.role == NRRoleRunner)
    {
        cell.linkLabel.text = [NSString stringWithFormat:@"%d", c.baseLink];
    }
    else
    {
        cell.linkLabel.text = @"";
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

-(void) showImage:(UIButton*)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    NSMutableArray* arr = self.identities[indexPath.section];
    Card* card = arr[indexPath.row];
    
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    rect.origin.x = sender.frame.origin.x;
    [CardImageViewPopover showForCard:card fromRect:rect inView:self.tableView];
}

@end
