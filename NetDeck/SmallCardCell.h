//
//  SmallCardCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"

@interface SmallCardCell : CardCell

@property IBOutlet UILabel* name;
@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UILabel* factionLabel;
@property IBOutlet UIStepper* copiesStepper;
@property IBOutlet UIView* mwlMarker;

@end
