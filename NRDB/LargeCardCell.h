//
//  LargeCardCell.h
//  NRDB
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CardCounter, Deck;

@interface LargeCardCell : UITableViewCell

@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UILabel* name;
@property IBOutlet UILabel* type;
@property IBOutlet UILabel* cost;
@property IBOutlet UILabel* strength;
@property IBOutlet UILabel* mu;
@property IBOutlet UILabel* copiesLabel;
@property IBOutlet UIStepper* copiesStepper;

@property IBOutlet UIView* pip1;
@property IBOutlet UIView* pip2;
@property IBOutlet UIView* pip3;
@property IBOutlet UIView* pip4;
@property IBOutlet UIView* pip5;

@property Deck* deck;
@property (nonatomic) CardCounter* cardCounter;

-(IBAction)copiesChanged:(id)sender;

@end
