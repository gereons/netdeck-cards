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
#import "DeckHistorySectionHeaderView.h"
#import "Notifications.h"
#import "CardImageViewPopover.h"

@interface DeckHistoryPopup ()

@property Deck* deck;
@property NSDateFormatter* dateFormatter;

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
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
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
    
    self.titleLabel.text = l10n(@"Editing History");
    [self.closeButton setTitle:l10n(@"Done") forState:UIControlStateNormal];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void) revertTo:(UIButton*)sender
{
    NSAssert(sender.tag < self.deck.revisions.count, @"invalid tag");
    DeckChangeSet* dcs = self.deck.revisions[sender.tag];
    // NSLog(@"revert to %d %@", sender.tag, [self.dateFormatter stringFromDate:dcs.timestamp]);

    [self.deck resetToCards:dcs.cards];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
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
    return dcs.initial ? 1 : dcs.changes.count;
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
    cell.textLabel.text = @"";
    
    DeckChangeSet* dcs = self.deck.revisions[indexPath.section];
    
    if (dcs.initial)
    {
        cell.textLabel.text = l10n(@"Initial Version");
    }
    else
    {
        if (indexPath.row < dcs.changes.count)
        {
            DeckChange* dc = dcs.changes[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%+ld %@", (long)dc.count, dc.card.name];
        }
    }
    
    return cell;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray* views = [[NSBundle mainBundle] loadNibNamed:@"DeckHistorySectionHeaderView" owner:self options:nil];
    DeckHistorySectionHeaderView* header = views[0];
    
    DeckChangeSet* dcs = self.deck.revisions[section];
    header.dateLabel.text = [self.dateFormatter stringFromDate:dcs.timestamp];
    
    [header.revertButton setTitle:l10n(@"Revert") forState:UIControlStateNormal];
    header.revertButton.tag = section;
    [header.revertButton addTarget:self action:@selector(revertTo:) forControlEvents:UIControlEventTouchUpInside];
    
    return header;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeckChangeSet* dcs = self.deck.revisions[indexPath.section];
    
    if (!dcs.initial)
    {
        if (indexPath.row < dcs.changes.count)
        {
            DeckChange* dc = dcs.changes[indexPath.row];
            
            CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
            [CardImageViewPopover showForCard:dc.card fromRect:rect inView:self.tableView];
        }
    }
}

@end
