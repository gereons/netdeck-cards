//
//  IphoneIdentityViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 18.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "IphoneIdentityViewController.h"
#import "EditDeckViewController.h"
#import "ImageCache.h"
#import "CardManager.h"
#import "Deck.h"

@interface IphoneIdentityViewController ()

@property Card* selectedIdentity;
@property NSArray* identities;

@end

@implementation IphoneIdentityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.title = l10n(@"Choose Identity");
    
    self.identities = [CardManager identitiesForRole:self.role];
}

-(void) cancelClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) okClicked:(id)sender
{
    if (self.deck)
    {
        [self.deck addCard:self.selectedIdentity copies:1];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        Deck* deck = [[Deck alloc] init];
        deck.role = self.role;
        if (self.selectedIdentity)
        {
            [deck addCard:self.selectedIdentity copies:1];
        }

        EditDeckViewController* edit = [[EditDeckViewController alloc] initWithNibName:@"EditDeckViewController" bundle:nil];
        edit.deck = deck;
        
        NSMutableArray* vcs = self.navigationController.viewControllers.mutableCopy;
        [vcs removeLastObject];
        [vcs addObject:edit];
        [self.navigationController setViewControllers:vcs animated:YES];
    }
}

#pragma mark - tableview

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.identities.count;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"idCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    Card* card = self.identities[indexPath.row];
    cell.textLabel.text = card.name;
    cell.textLabel.textColor = card.factionColor;
    
    if (self.role == NRRoleRunner)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d/%d - %d Link", card.minimumDecksize, card.influenceLimit, card.baseLink];
    }
    else
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d/%d", card.minimumDecksize, card.influenceLimit];
    }
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Card* card = self.identities[indexPath.row];
    self.selectedIdentity = card;
}


@end
