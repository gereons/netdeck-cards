//
//  BrowserFilterViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 02.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "BrowserFilterViewController.h"
#import "BrowserResultViewController.h"
#import "CardManager.h"
#import "CardList.h"
#import "CardType.h"
#import "CardSets.h"
#import "Faction.h"
#import "CardFilterPopover.h"

enum { TYPE_BUTTON, FACTION_BUTTON, SET_BUTTON, SUBTYPE_BUTTON };

@interface BrowserFilterViewController ()

@property BrowserResultViewController* browser;
@property SubstitutableNavigationController* snc;

@property CardList* cardList;
@property NRRole role;
@property NRSearchScope scope;
@property NSString* searchText;

@property NSString* selectedType;
@property NSSet* selectedTypes;
@property NSMutableDictionary* selectedValues;

@end

@implementation BrowserFilterViewController

- (id) init
{
    if ((self = [super initWithNibName:@"BrowserFilterViewController" bundle:nil]))
    {
        self.browser = [[BrowserResultViewController alloc] initWithNibName:@"BrowserResultViewController" bundle:nil];
        self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:self.browser];
        
        self.role = NRRoleNone;
        self.cardList = [CardList browserInitForRole:self.role];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.title = l10n(@"Browser");
    
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Clear") style:UIBarButtonItemStylePlain target:self action:@selector(clearFiltersClicked:)];
    
    // side
    [self.sideSelector setTitle:l10n(@"Both") forSegmentAtIndex:0];
    [self.sideSelector setTitle:l10n(@"Runner") forSegmentAtIndex:1];
    [self.sideSelector setTitle:l10n(@"Corp") forSegmentAtIndex:2];
    self.sideLabel.text = l10n(@"Side:");
    
    // text/scope
    [self.scopeSelector setTitle:l10n(@"All") forSegmentAtIndex:0];
    [self.scopeSelector setTitle:l10n(@"Name") forSegmentAtIndex:1];
    [self.scopeSelector setTitle:l10n(@"Text") forSegmentAtIndex:2];
    self.searchLabel.text = l10n(@"Search in:");
    self.scope = NRSearchAll;
    self.textField.delegate = self;
    
    // sliders
    self.costSlider.maximumValue = 1+(self.role == NRRoleRunner ? [CardManager maxRunnerCost] : [CardManager maxCorpCost]);
    self.costSlider.minimumValue = 0;
    [self costChanged:nil];
    
    self.muSlider.maximumValue = 1+[CardManager maxMU];
    self.muSlider.minimumValue = 0;
    [self muChanged:nil];
    
    self.strengthSlider.maximumValue = 1+[CardManager maxStrength];
    self.strengthSlider.minimumValue = 0;
    [self strengthChanged:nil];
    
    self.influenceSlider.maximumValue = 1+[CardManager maxInfluence];
    self.influenceSlider.minimumValue = 0;
    [self influenceChanged:nil];
    
    self.apSlider.maximumValue = 1+[CardManager maxAgendaPoints];
    self.apSlider.minimumValue = 0;
    [self apChanged:nil];
    
    [self.costSlider setThumbImage:[UIImage imageNamed:@"credit_slider"] forState:UIControlStateNormal];
    [self.muSlider setThumbImage:[UIImage imageNamed:@"mem_slider"] forState:UIControlStateNormal];
    [self.strengthSlider setThumbImage:[UIImage imageNamed:@"strength_slider"] forState:UIControlStateNormal];
    [self.influenceSlider setThumbImage:[UIImage imageNamed:@"influence_slider"] forState:UIControlStateNormal];
    [self.apSlider setThumbImage:[UIImage imageNamed:@"point_slider"] forState:UIControlStateNormal];
    
    // buttons
    self.typeButton.tag = TYPE_BUTTON;
    self.setButton.tag = SET_BUTTON;
    self.factionButton.tag = FACTION_BUTTON;
    self.subtypeButton.tag = SUBTYPE_BUTTON;
    
    self.typeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.setButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.factionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.subtypeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self.snc;

    [self clearFiltersClicked:nil];
}

#pragma mark - buttons

-(void) clearFiltersClicked:(id)sender
{
    // reset segment controllers
    self.role = NRRoleNone;
    self.sideSelector.selectedSegmentIndex = 0;
    self.scopeSelector.selectedSegmentIndex = 0;
    
    // clear textfield
    self.textField.text = @"";
    self.searchText = @"";
    self.scope = NRSearchAll;
    
    // reset sliders
    self.apSlider.value = 0;
    [self apChanged:nil];
    self.muSlider.value = 0;
    [self muChanged:nil];
    self.influenceSlider.value = 0;
    [self influenceChanged:nil];
    self.strengthSlider.value = 0;
    [self strengthChanged:nil];
    self.costSlider.value = 0;
    [self costChanged:nil];
    
    // reset switches
    self.uniqueSwitch.on = NO;
    self.limitedSwitch.on = NO;
    
    self.cardList = [CardList browserInitForRole:self.role];
    [self.cardList clearFilters];
    [self.browser updateDisplay:self.cardList];
    
    // type selection
    self.selectedType = kANY;
    self.selectedTypes = nil;
    self.selectedValues = [NSMutableDictionary dictionary];
}

-(IBAction)sideSelected:(UISegmentedControl*)sender
{
    switch (sender.selectedSegmentIndex)
    {
        case 0:
            self.role = NRRoleNone;
            break;
        case 1:
            self.role = NRRoleRunner;
            break;
        case 2:
            self.role = NRRoleCorp;
            break;
    }
    
    self.cardList = [CardList browserInitForRole:self.role];
    [self.cardList clearFilters];
    [self.browser updateDisplay:self.cardList];
}

#pragma mark - buttons for popovers

-(void) typeClicked:(UIButton*)sender
{
    TableData* data;
    if (self.role == NRRoleNone)
    {
        data = [CardType allTypes];
    }
    else
    {
        data = [[TableData alloc] initWithValues:[CardType typesForRole:self.role]];
    }
    id selected = [self.selectedValues objectForKey:@(TYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Type" selected:selected];
}

-(void) setClicked:(UIButton*)sender
{
    id selected = [self.selectedValues objectForKey:@(SET_BUTTON)];
    [CardFilterPopover showFromButton:sender inView:self entries:[CardSets allSetsForTableview] type:@"Set" selected:selected];
}

-(void) subtypeClicked:(UIButton*)sender
{
    TableData* data;
    if (self.role == NRRoleNone)
    {
        NSArray* runner;
        NSArray* corp;
        if (self.selectedTypes)
        {
            runner = [CardManager subtypesForRole:NRRoleRunner andTypes:self.selectedTypes includeIdentities:YES];
            corp = [CardManager subtypesForRole:NRRoleCorp andTypes:self.selectedTypes includeIdentities:YES];
        }
        else
        {
            runner = [CardManager subtypesForRole:NRRoleRunner andType:self.selectedType includeIdentities:YES];
            corp = [CardManager subtypesForRole:NRRoleCorp andType:self.selectedType includeIdentities:YES];
        }
        NSMutableArray* sections = [NSMutableArray array];
        NSMutableArray* values = [NSMutableArray array];
        [values addObject:@[ kANY ]];
        [sections addObject:@""];
        if (runner.count > 1)
        {
            [values addObject:runner];
            [sections addObject:l10n(@"Runner")];
        }
        if (corp.count > 1)
        {
            [values addObject:corp];
            [sections addObject:l10n(@"Corp")];
        }
        
        data = [[TableData alloc] initWithSections:sections andValues:values];
    }
    else
    {
        NSMutableArray* arr;
        if (self.selectedTypes)
        {
            arr = [CardManager subtypesForRole:self.role andTypes:self.selectedTypes includeIdentities:YES];
        }
        else
        {
            arr = [CardManager subtypesForRole:self.role andType:self.selectedType includeIdentities:YES];
        }
        [arr insertObject:kANY atIndex:0];
        data = [[TableData alloc] initWithValues:arr];
    }
    id selected = [self.selectedValues objectForKey:@(SUBTYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Subtype" selected:selected];
}

-(void) factionClicked:(UIButton*)sender
{
    TableData* data;
    
    if (self.role == NRRoleNone)
    {
        data = [Faction allFactions];
    }
    else
    {
        data = [[TableData alloc] initWithValues:[Faction factionsForRole:self.role]];
    }
    id selected = [self.selectedValues objectForKey:@(FACTION_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Faction" selected:selected];
}

-(void) filterCallback:(UIButton *)button value:(NSObject *)object
{
    NSString* value = [object isKindOfClass:[NSString class]] ? (NSString*)object : nil;
    NSSet* values = [object isKindOfClass:[NSSet class]] ? (NSSet*)object : nil;
    NSAssert(value != nil || values != nil, @"values");
    
    if (button.tag == TYPE_BUTTON)
    {
        if (value)
        {
            self.selectedType = value;
            self.selectedTypes = nil;
        }
        if (values)
        {
            self.selectedType = @"";
            self.selectedTypes = values;
        }
        
        [self resetButton:SUBTYPE_BUTTON];
    }
    [self.selectedValues setObject:value ? value : values forKey:@(button.tag)];
    
    NSLog(@"button: %d", button.tag);
    NSLog(@"value: %@", value ? value : values);
    
    SEL selector;
    switch (button.tag)
    {
        case TYPE_BUTTON:
            selector = value ? @selector(filterByType:) : @selector(filterByTypes:);
            break;
        case SUBTYPE_BUTTON:
            selector = value ? @selector(filterBySubtype:) : @selector(filterBySubtypes:);
            break;
        case FACTION_BUTTON:
            selector = value ? @selector(filterByFaction:) : @selector(filterByFactions:);
            break;
        case SET_BUTTON:
            selector = value ? @selector(filterBySet:) : @selector(filterBySets:);
            break;
    }
    id obj = value ? value : values;
    // see https://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
    // for why we can't simply call [self.cardList performSelector:selector withObject:obj]
    IMP imp = [self.cardList methodForSelector:selector];
    void (*func)(id, SEL, id) = (void*)imp;
    func(self.cardList, selector, obj);
    
    [self.browser updateDisplay:self.cardList];
}

-(void) resetAllButtons
{
    [self resetButton:TYPE_BUTTON];
    [self resetButton:SET_BUTTON];
    [self resetButton:FACTION_BUTTON];
    [self resetButton:SUBTYPE_BUTTON];
}

-(void) resetButton:(NSInteger)tag
{
    UIButton* btn;
    NSString* pfx;
    switch (tag)
    {
        case SET_BUTTON:
        {
            btn = self.setButton;
            pfx = @"Set";
            break;
        }
        case TYPE_BUTTON:
        {
            btn = self.typeButton;
            pfx = @"Type";
            // reset subtypes to "any"
            [self resetButton:SUBTYPE_BUTTON];
            break;
        }
        case SUBTYPE_BUTTON:
        {
            btn = self.subtypeButton;
            pfx = @"Subtype";
            break;
        }
        case FACTION_BUTTON:
        {
            btn = self.factionButton;
            pfx = @"Faction";
            break;
        }
    }
    
    [self.selectedValues setObject:kANY forKey:@(tag)];
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", l10n(pfx), l10n(kANY)] forState:UIControlStateNormal];
    
    NSAssert(btn != nil, @"no button");
}

#pragma mark - text search

-(IBAction)scopeSelected:(UISegmentedControl*)sender
{
    switch (sender.selectedSegmentIndex)
    {
        case 0:
            self.scope = NRSearchAll;
            break;
        case 1:
            self.scope = NRSearchName;
            break;
        case 2:
            self.scope = NRSearchText;
            break;
    }
    
    [self filterWithText];
}

-(void) filterWithText
{
    switch (self.scope)
    {
        case NRSearchText:
            [self.cardList filterByText:self.searchText];
            break;
        case NRSearchAll:
            [self.cardList filterByTextOrName:self.searchText];
            break;
        case NRSearchName:
            [self.cardList filterByName:self.searchText];
            break;
    }
    [self.browser updateDisplay:self.cardList];
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.searchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    // NSLog(@"search: %d %@", self.scope, self.searchText);
    [self filterWithText];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.searchText = @"";
    [self filterWithText];
    return YES;
}

#pragma mark - sliders

-(IBAction)influenceChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.influenceLabel.text = [NSString stringWithFormat:l10n(@"Influence: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByInfluence:value];
    [self.browser updateDisplay:self.cardList];
}

-(IBAction)costChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.costLabel.text = [NSString stringWithFormat:l10n(@"Cost: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByCost:value];
    [self.browser updateDisplay:self.cardList];
}

-(IBAction)strengthChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.strengthLabel.text = [NSString stringWithFormat:l10n(@"Strength: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByStrength:value];
    [self.browser updateDisplay:self.cardList];
}

-(IBAction)apChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.apLabel.text = [NSString stringWithFormat:l10n(@"AP: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByAgendaPoints:value];
    [self.browser updateDisplay:self.cardList];
}

-(IBAction)muChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.muLabel.text = [NSString stringWithFormat:l10n(@"MU: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByMU:value];
    [self.browser updateDisplay:self.cardList];
}

#pragma mark - switches

-(IBAction)uniqueChanged:(UISwitch*)sender
{
    [self.cardList filterByUniqueness:sender.on];
    [self.browser updateDisplay:self.cardList];
}

-(IBAction)limitedChanged:(UISwitch*)sender
{
    [self.cardList filterByLimited:sender.on];
    [self.browser updateDisplay:self.cardList];
}

-(IBAction)altartChanged:(UISwitch*)sender
{
    [self.cardList filterByAltArt:sender.on];
    [self.browser updateDisplay:self.cardList];
}

@end
