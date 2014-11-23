//
//  DeckHistoryPopup.m
//  NRDB
//
//  Created by Gereon Steffens on 23.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckHistoryPopup.h"
#import "Deck.h"
#import "DeckChangeSet.h"
#import "DeckChange.h"

@interface DeckHistoryPopup ()

@property Deck* deck;

@end

@implementation DeckHistoryPopup

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc
{
    DeckHistoryPopup* dhp = [[DeckHistoryPopup alloc] initWithDeck:deck];
    
    [vc presentViewController:dhp animated:NO completion:nil];
}

-(id) initWithDeck:(Deck*)deck
{
    if ((self = [self initWithNibName:@"DeckHistoryPopup" bundle:nil]))
    {
        self.deck = deck;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

-(void) dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark tableview

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.deck.revisions.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DeckChangeSet* dcs = self.deck.revisions[section];
    
    return dcs.changes.count;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"historyCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    DeckChangeSet* dcs = self.deck.revisions[indexPath.section];
    DeckChange* dc = dcs.changes[indexPath.row];
    
    NSString* op = dc.op == NRDeckChangeAddCard ? @"+" : @"-";
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %d %@", op, dc.count, dc.card.name];
    
    return cell;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    DeckChangeSet* dcs = self.deck.revisions[section];
    return [dcs.timestamp description];
}

@end
