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

@interface BrowserFilterViewController ()

@property BrowserResultViewController* browser;
@property SubstitutableNavigationController* snc;

@property CardList* cardList;
@property NRRole role;

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
    
    [self.sideSelector setTitle:l10n(@"Both") forSegmentAtIndex:0];
    [self.sideSelector setTitle:l10n(@"Runner") forSegmentAtIndex:1];
    [self.sideSelector setTitle:l10n(@"Corp") forSegmentAtIndex:2];
    self.sideLabel.text = l10n(@"Side:");
    
    [self.scopeSelector setTitle:l10n(@"All") forSegmentAtIndex:0];
    [self.scopeSelector setTitle:l10n(@"Name") forSegmentAtIndex:1];
    [self.scopeSelector setTitle:l10n(@"Text") forSegmentAtIndex:2];
    self.searchLabel.text = l10n(@"Search in:");
    
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
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self.snc;
    
    self.cardList = [CardList browserInitForRole:self.role];
    [self.cardList clearFilters];
    [self.browser updateDisplay:self.cardList];
}

#pragma mark buttons

-(void) clearFiltersClicked:(id)sender
{
    [self.cardList clearFilters];
    [self.browser updateDisplay:self.cardList];
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

-(IBAction)scopeSelected:(id)sender {}
-(IBAction)typeClicked:(id)sender {}
-(IBAction)subtypeClicked:(id)sender {}
-(IBAction)factionClicked:(id)sender {}
-(IBAction)setClicked:(id)sender {}

#pragma mark sliders

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

#pragma mark switches

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

@end
