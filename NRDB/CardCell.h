//
//  CardCell.h
//  NRDB
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CardCounter;

@interface CardCell : UITableViewCell

@property IBOutlet UILabel* influence;
@property IBOutlet UILabel* name;
@property IBOutlet UILabel* type;
@property IBOutlet UILabel* cost;
@property IBOutlet UILabel* strength;
@property IBOutlet UILabel* mu;
@property IBOutlet UILabel* copiesLabel;
@property IBOutlet UIStepper* copiesStepper;

@property (nonatomic) CardCounter* cardCounter;

-(IBAction)copiesChanged:(id)sender;

@end
