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
        TableData* td = [PackManager packsForTableview:NRPackUsageAll];
        self.sections = td.sections.mutableCopy;
        self.values = td.values.mutableCopy;
        
        if (self.values.count > 1) {
            // add "number of core sets" entry
            Pack* numCores = [[Pack alloc] init];
            numCores.name = l10n(@"Number of Core Sets");
            numCores.settingsKey = SettingsKeys.NUM_CORES;
            NSMutableArray* arr = [self.values[1] mutableCopy];
            [arr insertObject:numCores atIndex:1];
            self.values[1] = arr;
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
    [self.tableView reloadData];
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
