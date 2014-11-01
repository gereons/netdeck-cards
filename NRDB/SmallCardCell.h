//
//  SmallCardCell.h
//  NRDB
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"

@interface SmallCardCell : CardCell

@property IBOutlet UILabel* name;
@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UILabel* factionLabel;
@property IBOutlet UIStepper* copiesStepper;

@end
