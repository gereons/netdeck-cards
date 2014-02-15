//
//  DeckAnalysisViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 10.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckAnalysisViewController.h"
#import "CostStats.h"
#import "StrengthStats.h"
#import "Deck.h"

@interface DeckAnalysisViewController ()

@property Deck* deck;
@property NSArray* errors;
@property CostStats* costStats;
@property StrengthStats* strengthStats;

@end

@implementation DeckAnalysisViewController

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc
{
    DeckAnalysisViewController* davc = [[DeckAnalysisViewController alloc] initWithDeck:deck];
    
    [vc presentViewController:davc animated:NO completion:nil];
}

- (id)initWithDeck:(Deck*)deck
{
    self = [super initWithNibName:@"DeckAnalysisViewController" bundle:nil];
    if (self) {
        self.deck = deck;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        
        self.errors = [deck checkValidity];
        self.costStats = [[CostStats alloc] initWithDeck:deck];
        self.strengthStats = [[StrengthStats alloc] initWithDeck:deck];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) done:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark tableview

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
            return 44;
        case 1:
            return self.costStats.height;
        case 2:
            return self.strengthStats.height;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return MAX(1, self.errors.count);
        case 1:
        case 2:
            return 1;
    }
    return 0;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Deck Validity";
        case 1:
            if (self.costStats.height > 0) return @"Cost Distribution";
            break;
        case 2:
            if (self.strengthStats.height > 0) return @"Strength Distribution";
            break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"analysisCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    switch (indexPath.section)
    {
        case 0:
            cell.textLabel.font = [UIFont systemFontOfSize:15];
            
            if (self.errors.count > 0)
            {
                cell.textLabel.text = [self.errors objectAtIndex:indexPath.row];
                cell.textLabel.textColor = [UIColor redColor];
            }
            else
            {
                cell.textLabel.text = @"Deck is valid";
                cell.textLabel.textColor = [UIColor blackColor];
            }
            break;
        case 1:
            [cell.contentView addSubview:self.costStats.hostingView];
            break;
        case 2:
            [cell.contentView addSubview:self.strengthStats.hostingView];
            break;
    }
    
    return cell;
}


@end
