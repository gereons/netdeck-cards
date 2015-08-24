//
//  FilterViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 24.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "MultiSelectSegmentedControl.h"

@class Card, CardList;

@interface FilterViewController : UIViewController<MultiSelectSegmentedControlDelegate>

@property IBOutlet UILabel* factionLabel;
@property IBOutlet MultiSelectSegmentedControl* factionControl;

@property IBOutlet UILabel* typeLabel;
@property IBOutlet MultiSelectSegmentedControl* typeControl;

@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UISlider* influenceSlider;

@property IBOutlet UILabel* strengthLabel;
@property IBOutlet UISlider* strengthSlider;

@property IBOutlet UILabel* muApLabel;
@property IBOutlet UISlider* muApSlider;

@property IBOutlet UILabel* costLabel;
@property IBOutlet UISlider* costSlider;

@property NRRole role;
@property Card* identity;
@property CardList* cardList;

-(IBAction)influenceChanged:(id)sender;
-(IBAction)strengthChanged:(id)sender;
-(IBAction)muApChanged:(id)sender;
-(IBAction)costChanged:(id)sender;

@end
