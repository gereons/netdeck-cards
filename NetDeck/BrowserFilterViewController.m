//
//  BrowserFilterViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 02.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "BrowserFilterViewController.h"
#import "BrowserResultViewController.h"
#import "CardFilterPopover.h"

enum { TYPE_BUTTON, FACTION_BUTTON, SET_BUTTON, SUBTYPE_BUTTON };

@interface BrowserFilterViewController ()

@property BrowserResultViewController* browser;
@property UINavigationController* navController;

@property CardList* cardList;
@property NRRole role;
@property NRSearchScope scope;
@property NSString* searchText;

@property NSString* selectedType;
@property NSSet* selectedTypes;
@property NSMutableDictionary* selectedValues;

@property BOOL initializing;

@end

@implementation BrowserFilterViewController

static NSMutableArray* subtypeCollapsedSections;

+(void) initialize
{
    subtypeCollapsedSections = [NSMutableArray arrayWithArray:@[ @NO, @NO, @NO ]];
}

- (id) init
{
    if ((self = [super initWithNibName:@"BrowserFilterViewController" bundle:nil]))
    {
        self.browser = [[BrowserResultViewController alloc] initWithNibName:@"BrowserResultViewController" bundle:nil];
        self.navController = [[UINavigationController alloc] initWithRootViewController:self.browser];
        
        self.role = NRRoleNone;
        NRPackUsage packUsage = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.BROWSER_PACKS];
        self.cardList = [CardList browserInitForRole:self.role packUsage:packUsage];
    }
    return self;
}

-(void) dealloc
{
    self.textField.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.initializing = YES;
    LOG_EVENT(@"Browser", @{@"Device": @"iPad"});
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.title = l10n(@"Cards");
    
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
    self.scope = NRSearchScopeAll;
    self.textField.delegate = self;
    self.textField.placeholder = l10n(@"Search Cards");
    self.textField.clearButtonMode = UITextFieldViewModeAlways;
    
    // sliders
    NSInteger maxCost = MAX([CardManager maxRunnerCost], [CardManager maxCorpCost]);
    if (self.role != NRRoleNone)
    {
        maxCost = self.role == NRRoleRunner ? [CardManager maxRunnerCost] : [CardManager maxCorpCost];
    }
    self.costSlider.maximumValue = 1+maxCost;
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
    
    self.trashSlider.maximumValue = 1+[CardManager maxTrash];
    self.trashSlider.minimumValue = 0;
    [self trashChanged:nil];
    
    [self.costSlider setThumbImage:[UIImage imageNamed:@"credit_slider"] forState:UIControlStateNormal];
    [self.muSlider setThumbImage:[UIImage imageNamed:@"mem_slider"] forState:UIControlStateNormal];
    [self.strengthSlider setThumbImage:[UIImage imageNamed:@"strength_slider"] forState:UIControlStateNormal];
    [self.influenceSlider setThumbImage:[UIImage imageNamed:@"influence_slider"] forState:UIControlStateNormal];
    [self.apSlider setThumbImage:[UIImage imageNamed:@"point_slider"] forState:UIControlStateNormal];
    [self.trashSlider setThumbImage:[UIImage imageNamed:@"trash_slider"] forState:UIControlStateNormal];
    
    // switches
    self.uniqueLabel.text = l10n(@"Unique");
    self.limitedLabel.text = l10n(@"Limited");

    // buttons
    self.typeButton.tag = TYPE_BUTTON;
    self.setButton.tag = SET_BUTTON;
    self.factionButton.tag = FACTION_BUTTON;
    self.subtypeButton.tag = SUBTYPE_BUTTON;
    
    self.summaryLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightRegular];
    
    [self resetAllButtons];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // weird - if we do this in viewDidLoad, the buttons flicker.
    self.typeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.setButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.factionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.subtypeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(dismissKeyboard:) name:Notifications.BROWSER_FIND object:nil];
    [nc addObserver:self selector:@selector(dismissKeyboard:) name:Notifications.BROWSER_NEW object:nil];
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self.navController;

    [self clearFiltersClicked:nil];
    
    self.initializing = NO;
    [self updateResults];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL) canBecomeFirstResponder {
    return YES;
}

-(NSArray*) keyCommands {
    return @[
        KEYCMD(@"F", UIKeyModifierCommand, startTextSearch:, @"Find Cards"),
        KEYCMD(@"A", UIKeyModifierCommand, changeScopeKeyCmd:, @"Scope: All"),
        KEYCMD(@"N", UIKeyModifierCommand, changeScopeKeyCmd:, @"Scope: Name"),
        KEYCMD(@"T", UIKeyModifierCommand, changeScopeKeyCmd:, @"Scope: Text"),
        [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(escKeyPressed:)]
    ];
}

-(void) startTextSearch:(UIKeyCommand*) keyCmd {
    [self.textField becomeFirstResponder];
}

-(void) escKeyPressed:(UIKeyCommand*) keyCmd {
    [self.textField resignFirstResponder];
}


-(void) dismissKeyboard:(id)sender
{
    [self.textField resignFirstResponder];
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
    self.scope = NRSearchScopeAll;
    
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
    self.trashSlider.value = 0;
    [self trashChanged:nil];
    
    // reset switches
    self.uniqueSwitch.on = NO;
    self.limitedSwitch.on = NO;
    
    NRPackUsage packUsage = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.BROWSER_PACKS];
    
    self.cardList = [CardList browserInitForRole:self.role packUsage:packUsage];
    [self.cardList clearFilters];
    [self updateResults];
    
    // type selection
    self.selectedType = Constant.kANY;
    self.selectedTypes = nil;
    self.selectedValues = [NSMutableDictionary dictionary];
    
    [self resetAllButtons];
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
            self.apSlider.value = 0;
            [self apChanged:nil];
            self.trashSlider.value = 0;
            [self trashChanged:nil];
            break;
        case 2:
            self.role = NRRoleCorp;
            self.muSlider.value = 0;
            [self muChanged:nil];
            break;
    }

    // enable/disable sliders depending on role
    NSArray* runnerEnabled = @[ self.muLabel, self.muSlider ];
    NSArray* corpEnabled = @[ self.apLabel, self.apSlider, self.trashLabel, self.trashSlider ];
    for (UIControl* v in runnerEnabled)
    {
        v.enabled = self.role != NRRoleCorp;
    }
    for (UIControl* v in corpEnabled)
    {
        v.enabled = self.role != NRRoleRunner;
    }
    
    // remember which sets were selected
    id selectedSets = [self.selectedValues objectForKey:@(SET_BUTTON)];
    
    [self resetAllButtons];
    
    NSInteger maxCost = MAX([CardManager maxRunnerCost], [CardManager maxCorpCost]);
    if (self.role != NRRoleNone)
    {
        maxCost = self.role == NRRoleRunner ? [CardManager maxRunnerCost] : [CardManager maxCorpCost];
    }
    self.costSlider.maximumValue = 1+maxCost;
    self.costSlider.value = MIN(1+maxCost, round(self.costSlider.value));
    
    NRPackUsage packUsage = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.BROWSER_PACKS];
    self.cardList = [CardList browserInitForRole:self.role packUsage:packUsage];
    [self.cardList clearFilters];
    
    if (selectedSets)
    {
        [self filterCallback:self.setButton type:@"sets" value:selectedSets];
    }
    NSString* selected;
    if ([selectedSets isKindOfClass:[NSSet class]])
    {
        NSSet* set = (NSSet*) selectedSets;
        selected = set.count == 0 ? l10n(Constant.kANY) : (set.count == 1 ? [[set allObjects] objectAtIndex:0] : @"⋯");
    }
    else
    {
        selected = l10n(Constant.kANY);
    }
    NSString* title = [NSString stringWithFormat:@"%@: %@", l10n(@"Set"), selected];
    [self.setButton setTitle:title forState:UIControlStateNormal];
    
    [self costChanged:self.costSlider];
    [self.cardList filterByInfluence:round(self.influenceSlider.value)-1];
    [self.cardList filterByStrength:round(self.strengthSlider.value)-1];
    [self.cardList filterByCost:round(self.costSlider.value)-1];
    [self.cardList filterByAgendaPoints:round(self.apSlider.value)-1];
    [self.cardList filterByMU:round(self.muSlider.value)-1];
    [self.cardList filterByTrash:round(self.trashSlider.value)-1];
    
    [self.cardList filterByLimited:self.limitedSwitch.on];
    [self.cardList filterByUniqueness:self.uniqueSwitch.on];
    
    [self filterWithText];
    
    [self updateResults];
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
        NSMutableArray* types = [NSMutableArray arrayWithArray:[CardType typesForRole:self.role]];
        [types insertObject:[CardType name:NRCardTypeIdentity] atIndex:1];
        data = [[TableData alloc] initWithValues:types];
    }
    id selected = [self.selectedValues objectForKey:@(TYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Type" selected:selected];
}

-(void) setClicked:(UIButton*)sender
{
    id selected = [self.selectedValues objectForKey:@(SET_BUTTON)];

    NRPackUsage usePacks = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.BROWSER_PACKS];
    TableData* rawPacks = [PackManager packsForTableview:usePacks];
//    NSMutableArray* strValues = [NSMutableArray array];
//    for (NSArray* packs in rawPacks.values) {
//        NSMutableArray* strings = [NSMutableArray array];
//        for (Pack* pack in packs) {
//            [strings addObject:pack.name];
//        }
//        [strValues addObject:strings];
//    }
//    TableData* stringPacks = [[TableData alloc] initWithSections:rawPacks.sections andValues:strValues];
    TableData* stringPacks = [TableData convertPacksData:rawPacks];
    [CardFilterPopover showFromButton:sender inView:self entries:stringPacks type:@"Set" selected:selected];
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
        [values addObject:@[ Constant.kANY ]];
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
        data.collapsedSections = subtypeCollapsedSections;
    }
    else
    {
        NSMutableArray* arr;
        if (self.selectedTypes)
        {
            arr = [CardManager subtypesForRole:self.role andTypes:self.selectedTypes includeIdentities:YES].mutableCopy;
        }
        else
        {
            arr = [CardManager subtypesForRole:self.role andType:self.selectedType includeIdentities:YES].mutableCopy;
        }
        [arr insertObject:Constant.kANY atIndex:0];
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
        data = [Faction factionsForBrowser];
    }
    else
    {
        data = [[TableData alloc] initWithValues:[Faction factionsForRole:self.role]];
    }
    id selected = [self.selectedValues objectForKey:@(FACTION_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Faction" selected:selected];
}

-(void) filterCallback:(UIButton *)button type:(NSString*)type value:(NSObject *)object
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
    
    // NSLog(@"button: %d", button.tag);
    // NSLog(@"value: %@", value ? value : values);
    
    SEL selector = nil;
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
    
    [self updateResults];
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
            self.selectedType = Constant.kANY;
            self.selectedTypes = nil;
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
    NSAssert(btn != nil, @"no button");
    
    [self.selectedValues setObject:Constant.kANY forKey:@(tag)];
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", l10n(pfx), l10n(Constant.kANY)] forState:UIControlStateNormal];
}

#pragma mark - text search

-(void) changeScopeKeyCmd:(UIKeyCommand*)keyCommand {
    if ([keyCommand.input.lowercaseString isEqualToString:@"a"]) {
        self.scope = NRSearchScopeAll;
    }
    else if ([keyCommand.input.lowercaseString isEqualToString:@"n"]) {
        self.scope = NRSearchScopeName;
    }
    else if ([keyCommand.input.lowercaseString isEqualToString:@"t"]) {
        self.scope = NRSearchScopeText;
    }
    [self filterWithText];
}

-(IBAction)scopeSelected:(UISegmentedControl*)sender
{
    switch (sender.selectedSegmentIndex)
    {
        case 0:
            self.scope = NRSearchScopeAll;
            break;
        case 1:
            self.scope = NRSearchScopeName;
            break;
        case 2:
            self.scope = NRSearchScopeText;
            break;
    }
    
    [self filterWithText];
}

-(void) filterWithText
{
    switch (self.scope)
    {
        case NRSearchScopeText:
            [self.cardList filterByText:self.searchText];
            break;
        case NRSearchScopeAll:
            [self.cardList filterByTextOrName:self.searchText];
            break;
        case NRSearchScopeName:
            [self.cardList filterByName:self.searchText];
            break;
    }
    [self updateResults];
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

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    return NO;
}

#pragma mark - sliders

-(IBAction)influenceChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"inf: %f %d", sender.value, value);
    sender.value = value--;
    self.influenceLabel.text = [NSString stringWithFormat:l10n(@"Influence: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByInfluence:value];
    [self updateResults];
}

-(IBAction)costChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"cost: %f %d", sender.value, value);
    sender.value = value--;
    self.costLabel.text = [NSString stringWithFormat:l10n(@"Cost: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByCost:value];
    [self updateResults];
}

-(IBAction)strengthChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"str: %f %d", sender.value, value);
    sender.value = value--;
    self.strengthLabel.text = [NSString stringWithFormat:l10n(@"Strength: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByStrength:value];
    [self updateResults];
}

-(IBAction)apChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"ap: %f %d", sender.value, value);
    sender.value = value--;
    self.apLabel.text = [NSString stringWithFormat:l10n(@"AP: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByAgendaPoints:value];
    [self updateResults];
}

-(IBAction)muChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.muLabel.text = [NSString stringWithFormat:l10n(@"MU: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByMU:value];
    [self updateResults];
}

-(IBAction)trashChanged:(UISlider*)sender
{
    int value = round(sender.value);
    // NSLog(@"trash: %f %d", sender.value, value);
    sender.value = value--;
    self.trashLabel.text = [NSString stringWithFormat:l10n(@"Trash: %@"), value == -1 ? l10n(@"All") : [@(value) stringValue]];
    [self.cardList filterByTrash:value];
    [self updateResults];
}

#pragma mark - switches

-(IBAction)uniqueChanged:(UISwitch*)sender
{
    [self.cardList filterByUniqueness:sender.on];
    [self updateResults];
}

-(IBAction)limitedChanged:(UISwitch*)sender
{
    [self.cardList filterByLimited:sender.on];
    [self updateResults];
}

#pragma mark update results

-(void) updateResults
{
    NSUInteger count = self.cardList.count;
    NSString* fmt = count == 1 ? l10n(@"%lu matching card") : l10n(@"%lu matching cards");
    self.summaryLabel.text = [NSString stringWithFormat:fmt, count ];
    if (!self.initializing)
    {
        [self.browser updateDisplay:self.cardList];
    }
}

@end
