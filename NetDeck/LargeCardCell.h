//
//  LargeCardCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"

@interface LargeCardCell : CardCell

@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UILabel* name;
@property IBOutlet UILabel* type;

@property IBOutlet UILabel* label1;
@property IBOutlet UILabel* label2;
@property IBOutlet UILabel* label3;
@property IBOutlet UIImageView* icon1;
@property IBOutlet UIImageView* icon2;
@property IBOutlet UIImageView* icon3;

@property IBOutlet UILabel* copiesLabel;
@property IBOutlet UIStepper* copiesStepper;

@property IBOutlet UIView* pip1;
@property IBOutlet UIView* pip2;
@property IBOutlet UIView* pip3;
@property IBOutlet UIView* pip4;
@property IBOutlet UIView* pip5;

@end
