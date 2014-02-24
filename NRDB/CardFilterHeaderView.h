//
//  CardFilterHeaderView.h
//  NRDB
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CardFilterHeaderView : UIView <UITextFieldDelegate>

@property (nonatomic) NRRole role;

@property IBOutlet UITextField* searchField;
@property IBOutlet UISegmentedControl* searchScope;

@property IBOutlet UISlider* costSlider;
@property IBOutlet UILabel* costLabel;

@property IBOutlet UISlider* strengthSlider;
@property IBOutlet UILabel* strengthLabel;

@property IBOutlet UILabel* muLabel;
@property IBOutlet UISlider* muSlider;

@property IBOutlet UILabel* apLabel;
@property IBOutlet UISlider* apSlider;

@property IBOutlet UISlider* influenceSlider;
@property IBOutlet UILabel* influenceLabel;

@property IBOutlet UIButton* typeButton;
@property IBOutlet UIButton* subtypeButton;
@property IBOutlet UIButton* factionButton;
@property IBOutlet UIButton* setButton;

-(IBAction)strengthValueChanged:(id)sender;
-(IBAction)costValueChanged:(id)sender;
-(IBAction)muValueChanged:(id)sender;
-(IBAction)apValueChanged:(id)sender;
-(IBAction)influenceValueChanged:(id)sender;

-(IBAction)typeClicked:(id)sender;
-(IBAction)subtypeClicked:(id)sender;
-(IBAction)factionClicked:(id)sender;
-(IBAction)setClicked:(id)sender;

-(IBAction)scopeValueChanged:(id)sender;

-(void) clearFilters;

-(void) filterCallback:(UIButton*)button value:(NSObject*)value;

@end
