//
//  SetSelectionViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 13.02.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <SDCAlertView.h>

#import "SetSelectionViewController.h"
#import "SetSelectionCell.h"
#import "SettingsKeys.h"
#import "CardSets.h"
#import "CardSet.h"
#import "UIAlertAction+NRDB.h"

@interface SetSelectionViewController ()

@property NSMutableArray* sections;
@property NSMutableArray* values;

@end

@implementation SetSelectionViewController

-(id) init
{
    if ((self = [super init]))
    {
        TableData* td = [CardSets allKnownSetsForTableview];
        self.sections = td.sections.mutableCopy;
        self.values = td.values.mutableCopy;
        
        // set title for core / deluxe section
        self.sections[0] = l10n(@"Core Set and Deluxe Expansions");
        
        // add "number of core sets" entry
        CardSet* numCores = [[CardSet alloc] init];
        numCores.name = l10n(@"Number of Core Sets");
        numCores.settingsKey = NUM_CORES;
        NSMutableArray* arr = self.values[0];
        [arr insertObject:numCores atIndex:1];
        
        // add section for draft/unpublished ids
        [self.sections insertObject:l10n(@"Special Identities") atIndex:1];
        CardSet* draft = [[CardSet alloc] init];
        draft.name = l10n(@"Include Draft Identities");
        draft.settingsKey = USE_DRAFT_IDS;
        CardSet* unpub = [[CardSet alloc] init];
        unpub.name = l10n(@"Include Unpublished Identities");
        unpub.settingsKey = USE_UNPUBLISHED_IDS;
        
        [self.values insertObject:@[ draft, unpub] atIndex:1];
    }
    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"SetSelectionCell" bundle:nil] forCellReuseIdentifier:@"cell"];
}

-(void) toggleSwitch:(UISwitch*)sender
{
    NSInteger section = sender.tag / 1000;
    NSInteger row = sender.tag - (section * 1000);
    
    NSArray* arr = self.values[section];
    
    CardSet* cs = arr[row];
    // NSLog(@"toggle %d %@ %@", sender.tag, cs.name, cs.settingsKey);
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:sender.on forKey:cs.settingsKey];
    
    [CardSets clearDisabledSets];
}

-(void) coresAlert:(UIButton*) sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Number of Core Sets") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"1" handler:^(UIAlertAction *action) {
        [self changeCoreSets:1];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"2" handler:^(UIAlertAction *action) {
        [self changeCoreSets:2];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"3" handler:^(UIAlertAction *action) {
        [self changeCoreSets:3];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:NO completion:nil];
}

-(void) changeCoreSets:(int)numCores
{
    [[NSUserDefaults standardUserDefaults] setObject:@(numCores) forKey:NUM_CORES];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:0];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - table view

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.values[section];
    return arr.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections[section];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SetSelectionCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSArray* arr = self.values[indexPath.section];
    
    CardSet* cs = arr[indexPath.row];
    cell.setName.text = cs.name;
    
    [cell.setSwitch removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
    [cell.button removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if ([cs.settingsKey isEqualToString:NUM_CORES])
    {
        cell.setSwitch.hidden = YES;
        cell.button.hidden = NO;
        NSNumber* numCores = [settings objectForKey:NUM_CORES];
        [cell.button setTitle:numCores.stringValue forState:UIControlStateNormal];
        [cell.button addTarget:self action:@selector(coresAlert:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        cell.setSwitch.hidden = NO;
        cell.button.hidden = YES;
        cell.setSwitch.on = [settings boolForKey:cs.settingsKey];
        [cell.setSwitch addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
        
        cell.setSwitch.tag = indexPath.section * 1000 + indexPath.row;
    }
    
    return cell;
}

@end
