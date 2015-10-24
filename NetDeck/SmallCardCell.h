//
//  SmallCardCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"

@interface SmallCardCell : CardCell

@property IBOutlet UILabel* name;
@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UILabel* factionLabel;
@property IBOutlet UIStepper* copiesStepper;

@end
