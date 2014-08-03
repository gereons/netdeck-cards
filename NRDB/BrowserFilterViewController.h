//
//  BrowserFilterViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 02.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BrowserFilterViewController : UIViewController

@property IBOutlet UILabel* sideLabel;
@property IBOutlet UISegmentedControl* sideSelector;

@property IBOutlet UITextField* textField;
@property IBOutlet UILabel* searchLabel;
@property IBOutlet UISegmentedControl* scopeSelector;

@property IBOutlet UIButton* typeButton;
@property IBOutlet UIButton* subtypeButton;
@property IBOutlet UIButton* factionButton;
@property IBOutlet UIButton* setButton;

@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UISlider* influenceSlider;

@property IBOutlet UILabel* strengthLabel;
@property IBOutlet UISlider* strengthSlider;

@property IBOutlet UILabel* costLabel;
@property IBOutlet UISlider* costSlider;

@property IBOutlet UILabel* muLabel;
@property IBOutlet UISlider* muSlider;

@property IBOutlet UILabel* apLabel;
@property IBOutlet UISlider* apSlider;

@property IBOutlet UISwitch* uniqueSwitch;

@end
