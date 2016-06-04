//
//  SetSelectionViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 13.02.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "SetSelectionViewController.h"
#import "NRSwitch.h"

@interface SetSelectionViewController ()

@property NSMutableArray* sections;
@property NSMutableArray* values;

@end

@implementation SetSelectionViewController

-(id) init
{
    if ((self = [super init]))
    {
        TableData* td = [PackManager allKnownPacksForTableview];
        self.sections = td.sections.mutableCopy;
        self.values = td.values.mutableCopy;
        
        if (self.values.count != 0) {
            // set title for core / deluxe section
            self.sections[0] = l10n(@"Core Set and Deluxe Expansions");
            
            // add "number of core sets" entry
            Pack* numCores = [[Pack alloc] init];
            numCores.name = l10n(@"Number of Core Sets");
            numCores.settingsKey = SettingsKeys.NUM_CORES;
            NSMutableArray* arr = [self.values[0] mutableCopy];
            [arr insertObject:numCores atIndex:1];
            self.values[0] = arr;
            
            // add section for draft/unpublished ids
            [self.sections insertObject:l10n(@"Draft Identities") atIndex:1];
            Pack* draft = [[Pack alloc] init];
            draft.name = l10n(@"Include Draft Identities");
            draft.settingsKey = SettingsKeys.USE_DRAFT_IDS;
            
            [self.values insertObject:@[ draft ] atIndex:1];
        } else {
            // wtf. very rarely, there is no set data. and I have no idea why or how to reproduce :(
            // see crashlytics #102/#143/#155
            self.sections = @[ @"" ].mutableCopy;
            Pack* cs = [[Pack alloc] init];
            cs.name = l10n(@"No Card Data");
            cs.settingsKey = @"";
            self.values = @[ @[ cs ] ].mutableCopy;
        }
    }
    return self;
}

-(void) dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

-(void) coresAlert:(UIButton*) sender
{
    UIAlertController* alert = [UIAlertController alertWithTitle:l10n(@"Number of Core Sets") message:nil];
    
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
    [[NSUserDefaults standardUserDefaults] setObject:@(numCores) forKey:SettingsKeys.NUM_CORES];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:0];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - table view

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 33;
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

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat width = tableView.frame.size.width;
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 33)];
    view.backgroundColor = [UIColor colorWithRGB:0xEFEFF4];
    view.tag = section;
    view.userInteractionEnabled = YES;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(20, 2, width, 33)];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    label.text = [self.sections[section] uppercaseString];
    label.textColor = [UIColor colorWithRGB:0x6d6d72];
    [view addSubview:label];
    
    if (section > 1) {
        NRCycle cycle = section - 1; // section 2 == Genesis
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        BOOL on = NO;
        for (NSString* key in [PackManager keysForCycle:cycle]) {
            if ([settings boolForKey:key]) {
                on = YES;
            }
        }
        
        UISwitch* cycleSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width-66, 0, 50, 33)];
        cycleSwitch.tag = cycle;
        cycleSwitch.on = on;
        [cycleSwitch addTarget:self action:@selector(toggleCycle:) forControlEvents:UIControlEventValueChanged];
        [view addSubview:cycleSwitch];
    }
    
    return view;
}

-(void) toggleCycle:(UISwitch*)sender {
    NRCycle cycle = sender.tag;
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    for (NSString* key in [PackManager keysForCycle:cycle]) {
        [settings setBool:sender.on forKey:key];
    }
    [PackManager clearDisabledPacks];
    [self.tableView reloadData];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"setCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    Pack* cs = [self.values objectAtIndexPath:indexPath];

    cell.textLabel.text = cs.name;
    cell.accessoryView = nil;
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if ([cs.settingsKey isEqualToString:SettingsKeys.NUM_CORES]) {
        NSNumber* numCores = [settings objectForKey:SettingsKeys.NUM_CORES];
        UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(0, 0, 40, 30);
        [button setTitle:numCores.stringValue forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        [button addTarget:self action:@selector(coresAlert:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = button;
    } else if (cs.settingsKey != nil) {
        NRSwitch* setSwitch = [[NRSwitch alloc] initWithHandler:^(BOOL on) {
            [settings setBool:on forKey:cs.settingsKey];
            [PackManager clearDisabledPacks];
        }];
        setSwitch.on = [settings boolForKey:cs.settingsKey];
        cell.accessoryView = setSwitch;
    }
    
    return cell;
}

@end
