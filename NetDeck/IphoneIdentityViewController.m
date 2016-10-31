//
//  IphoneIdentityViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 18.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "IphoneIdentityViewController.h"
#import "EditDeckViewController.h"

@interface IphoneIdentityViewController ()

@property Card* selectedIdentity;
@property NSIndexPath* selectedIndexPath;
@property NSArray<NSArray<Card*>*>* identities;
@property NSArray<NSString*>* factionNames;

@end

@implementation IphoneIdentityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer* tableTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tableTap.numberOfTapsRequired = 2;
    [self.tableView addGestureRecognizer:tableTap];
    
    self.title = l10n(@"Choose Identity");
    
    
    self.cancelButton.title = l10n(@"Cancel");
    if (!self.deck)
    {
        NSMutableArray* barButtons = self.toolbar.items.mutableCopy;
        
        [barButtons removeObject:self.cancelButton];
        self.toolbar.items = barButtons;
    }
    
    self.selectedIdentity = self.deck.identity;
    
    TableData* identities = [CardManager identitiesForSelection:self.role];
    self.factionNames = identities.sections;
    self.identities = identities.values;
    
    self.selectedIndexPath = nil;
    for (NSInteger i=0; i<self.identities.count; ++i) {
        NSArray<Card*>* arr = self.identities[i];
        for (NSInteger j=0; j<arr.count; ++j) {
            Card* card = arr[j];
            if ([self.selectedIdentity.code isEqual:card.code]) {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:j inSection:i];
                break;
            }
        }
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.okButton.enabled = self.deck != nil && self.deck.identity != nil;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.selectedIndexPath)
    {
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}


-(void) doubleTap:(UITapGestureRecognizer*)gesture
{
    if (UIGestureRecognizerStateEnded != gesture.state) {
        return;
    }
    
    CGPoint point = [gesture locationInView:self.tableView];
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (indexPath == nil || self.selectedIdentity == nil) {
        return;
    }
    
    [self okClicked:nil];
}

-(void) okClicked:(id)sender
{
    if (self.deck)
    {
        [self.deck addCard:self.selectedIdentity copies:1];
        
        [self cancelClicked:sender];
    }
    else
    {
        Deck* deck = [[Deck alloc] init];
        deck.role = self.role;
        if (self.selectedIdentity)
        {
            [deck addCard:self.selectedIdentity copies:1];
        }
        
        NSInteger seq = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.FILE_SEQ] + 1;
        deck.name = [NSString stringWithFormat:@"Deck #%ld", (long)seq];

        EditDeckViewController* edit = [[EditDeckViewController alloc] initWithNibName:@"EditDeckViewController" bundle:nil];
        edit.deck = deck;
        
        NSMutableArray* vcs = self.navigationController.viewControllers.mutableCopy;
        [vcs removeLastObject];
        [vcs addObject:edit];
        [self.navigationController setViewControllers:vcs animated:YES];
    }
}

-(void) cancelClicked:(id)sender
{
    NSAssert(self.deck, @"no deck?");
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - tableview

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.identities[section];
    return arr.count;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.identities.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.factionNames[section];
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.backgroundColor = [UIColor whiteColor];
    if ([indexPath compare:self.selectedIndexPath] == NSOrderedSame)
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        cell.backgroundColor = [UIColor colorWithWhite:.97 alpha:1];
    }
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"idCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    Card* card = [self.identities objectAtIndexPath:indexPath];
    cell.textLabel.text = card.name;
    cell.textLabel.textColor = card.factionColor;
 
    NSString* influence = card.influenceLimit == -1 ? @"∞" : [NSString stringWithFormat:@"%ld", (long)card.influenceLimit];
    if (self.role == NRRoleRunner)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld/%@ · %ld Link", (long)card.minimumDecksize, influence, (long)card.baseLink];
    }
    else
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld/%@", (long)card.minimumDecksize, influence];
    }
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Card* card = [self.identities objectAtIndexPath:indexPath];
    self.selectedIdentity = card;
    
    NSMutableArray* reload = [NSMutableArray array];
    [reload addObject:indexPath];
    if (self.selectedIndexPath)
    {
        [reload addObject:self.selectedIndexPath];
    }
    self.selectedIndexPath = indexPath;
    [self.tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationNone];
    
    self.okButton.enabled = YES;
}


@end
