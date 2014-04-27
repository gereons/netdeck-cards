//
//  CardFilterPopover.m
//  NRDB
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardFilterPopover.h"
#import "CGRectUtils.h"
#import "Notifications.h"
#import "TableData.h"
#import "CardFilterHeaderView.h"

@interface CardFilterPopover ()

@property NSArray* sections;
@property NSArray* values;
@property UIButton* button;
@property NSString* type;
@property CardFilterHeaderView* headerView;
@property NSMutableSet* selectedValues;
@property NSMutableArray* sectionToggles;

@property int sectionCount; // number of non-empty section headers

@end

@implementation CardFilterPopover

static UIPopoverController* popover;

+(void) showFromButton:(UIButton *)button inView:(CardFilterHeaderView*)view entries:(TableData*)entries type:(NSString *)type selected:(id)preselected
{
    CardFilterPopover* filter = [[CardFilterPopover alloc] initWithNibName:@"CardFilterPopover" bundle:nil];
    filter.sections = entries.sections;
    filter.values = entries.values;
    filter.button = button;
    filter.type = type;
    filter.headerView = view;

    if ([preselected isKindOfClass:[NSSet class]])
    {
        filter.selectedValues = [[NSSet setWithSet:preselected] mutableCopy];
    }
    else
    {
        filter.selectedValues = [NSMutableSet set];
        if (preselected && ![preselected isEqualToString:kANY])
        {
            [filter.selectedValues addObject:preselected];
        }
    }
    filter.sectionToggles = [NSMutableArray array];
    
    filter.sectionCount = 0;
    for (NSString* s in entries.sections)
    {
        [filter.sectionToggles addObject:@(NO)];
        if (s.length > 0)
        {
            ++filter.sectionCount;
        }
    }
    
    popover = [[UIPopoverController alloc] initWithContentViewController:filter];
    popover.backgroundColor = [UIColor whiteColor];
    
    // make the popover height match the height of the inner tableView
    CGSize tableSize = filter.tableView.frame.size;
    popover.popoverContentSize = tableSize;
    
    [popover presentPopoverFromRect:button.frame inView:view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:NO];
}

+(void) dismiss
{
    [popover dismissPopoverAnimated:NO];
    popover = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self setTableHeight]; // wtf do i have to call this twice?
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setTableHeight]; // wtf do i have to call this twice?
}

#define CELL_HEIGHT     40
#define HEADER_HEIGHT   25

-(void) setTableHeight
{
    int h = 0;
    for (NSArray* arr in self.values)
    {
        h += CELL_HEIGHT * arr.count;
    }
    h += HEADER_HEIGHT * self.sectionCount;

    self.tableView.scrollEnabled = h > 700;
    h = MIN(h, 700);

    self.tableView.frame = CGRectSetHeight(self.tableView.frame, h);
}

#pragma mark tableview

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.values[section];
    return arr.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString* s = self.sections[section];
    return s.length > 0 ? HEADER_HEIGHT : 0;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* s = self.sections[section];
    return s.length > 0 ? s : nil;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, 200, HEADER_HEIGHT)];
    view.backgroundColor = [UIColor colorWithWhite:.9 alpha:1];
    view.tag = section;
    view.userInteractionEnabled = YES;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, HEADER_HEIGHT)];
    label.font = [UIFont boldSystemFontOfSize:15];
    label.text = self.sections[section];
    
    [view addSubview:label];

    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectSection:)];
    [view addGestureRecognizer:tap];
    
    return view;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"popupCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSArray* arr = self.values[indexPath.section];
    NSString* value = arr[indexPath.row];
    
    if ([value isEqualToString:kANY])
    {
        cell.textLabel.text = l10n(value);
    }
    else
    {
        cell.textLabel.text = value;
    }
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.textColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
    
    if ([self.selectedValues containsObject:value] && ![value isEqualToString:kANY])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* arr = self.values[indexPath.section];
    NSString* value = arr[indexPath.row];

    BOOL firstCell = indexPath.row == 0 && indexPath.section == 0;
    if (firstCell)
    {
        NSDictionary* userInfo = @{ @"type": [self.type lowercaseString], @"value": value };
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_FILTER object:self userInfo:userInfo];
        
        NSString* title = [NSString stringWithFormat:@"%@: %@", l10n(self.type), l10n(value) ];
        [self.button setTitle:title forState:UIControlStateNormal];
        
        [self.headerView filterCallback:self.button value:value];
        
        [CardFilterPopover dismiss];
    }
    else
    {
        NSAssert(self.selectedValues != nil, @"nil selectedValue");
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

        if ([self.selectedValues containsObject:value])
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.selectedValues removeObject:value];
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.selectedValues addObject:value];
        }
        
        [self notifyWithMultipleSelection];
    }
}

-(void) didSelectSection:(UIGestureRecognizer*)gesture
{
    NSInteger section = gesture.view.tag;
    
    BOOL on = [[self.sectionToggles objectAtIndex:section] boolValue];
    // NSString* s = self.sections[section];
    // NSLog(@"section toggle %@ %d", s, on);
    self.sectionToggles[section] = @(!on);
    
    if (!on)
    {
        [self.selectedValues addObjectsFromArray:self.values[section]];
    }
    else
    {
        for (NSString* s in self.values[section])
        {
            [self.selectedValues removeObject:s];
        }
    }
    
    // NSLog(@"selected: %@", self.selectedValues);
    
    [self.tableView reloadData];
    [self notifyWithMultipleSelection];
}

-(void) notifyWithMultipleSelection
{
    // NSLog(@"notify %@ %@", self.type, self.selectedValues);
    
    NSDictionary* userInfo = @{ @"type": [self.type lowercaseString], @"value": self.selectedValues };
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_FILTER object:self userInfo:userInfo];
    
    NSString* selected = self.selectedValues.count == 0 ? l10n(kANY) : (self.selectedValues.count == 1 ? [[self.selectedValues allObjects] objectAtIndex:0] : @"⋯");
    NSString* title = [NSString stringWithFormat:@"%@: %@", l10n(self.type), selected];
    [self.button setTitle:title forState:UIControlStateNormal];
    
    [self.headerView filterCallback:self.button value:self.selectedValues];
}
@end
