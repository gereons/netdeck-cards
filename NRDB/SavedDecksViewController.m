//
//  SavedDecksViewController.m
//  X-Wing Squads
//
//  Created by Gereon Steffens on 22.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "SavedDecksViewController.h"
#import "SavedDeckCell.h"
#import "DeckManager.h"
#import "Deck.h"
#import "Notifications.h"
#import "ImageCache.h"

@interface SavedDecksViewController ()

@property UIBarButtonItem* editButton;
@property NSMutableArray* decks; // of Deck*
@property NRRole role;

@end

@implementation SavedDecksViewController

-(id) initWithRole:(NRRole)role
{
    if ((self = [self initWithNibName:@"SavedDecksViewController" bundle:nil]))
    {
        self.role = role;
        self.decks = [self sortDecks:[DeckManager decksForRole:self.role]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    UINavigationItem* top = self.navigationController.navigationBar.topItem;
    
    top.title = self.role == NRRoleRunner ? l10n(@"Load Runner Deck") : l10n(@"Load Corp Deck");
    
    self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editToggle:)];
    self.editButton.possibleTitles = [NSSet setWithArray:@[ l10n(@"Edit"), l10n(@"Done") ]];
    self.editButton.title = l10n(@"Edit");
    
    top.rightBarButtonItems = @[ self.editButton ];
}

-(NSMutableArray*) sortDecks:(NSMutableArray*)arr
{
    NSArray* sorted = [arr sortedArrayUsingComparator:^NSComparisonResult(Deck* d1, Deck* d2) {
        NSComparisonResult res = [[d1.name lowercaseString] compare:[d2.name lowercaseString]];
        return res;
    }];
    
    return [sorted mutableCopy];
}

#pragma mark editing

-(void) editToggle:(id)sender
{
    BOOL editing = self.tableView.editing;
    
    editing = !editing;
    self.editButton.title = editing ? l10n(@"Done") : l10n(@"Edit");
    self.tableView.editing = editing;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        Deck* deck = [self.decks objectAtIndex:indexPath.row];
        
        [self.decks removeObjectAtIndex:indexPath.row];
        [DeckManager removeFile:deck.filename];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView endUpdates];
    }
}

#pragma mark table view - data source

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.decks.count;
}

- (SavedDeckCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"squadfile";
    
    Deck* deck = [self.decks objectAtIndex:indexPath.row];
    
    // NSLog(@"cell for %d %d", indexPath.section, indexPath.row);
    // Dequeue or create a cell of the appropriate type.
    SavedDeckCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[SavedDeckCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = deck.name;
    
    if (deck.identity != nil)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:l10n(@"%@ · %d Cards · %d Influence"), deck.identity.name, deck.size, deck.influence];
    }
    else
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:l10n(@"%d Cards · %d Influence"), deck.size, deck.influence];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Deck* deck = [self.decks objectAtIndex:indexPath.row];
    
    TF_CHECKPOINT(@"load deck");
    
    NSDictionary* userInfo = @{
                               @"filename" : deck.filename,
                               @"role" : @(self.role)
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_DECK object:self userInfo:userInfo];
}

@end
