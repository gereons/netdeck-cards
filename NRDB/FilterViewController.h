//
//  FilterViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 24.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "MultiSelectSegmentedControl.h"

@class CardList;

@interface FilterViewController : UIViewController<MultiSelectSegmentedControlDelegate>

@property IBOutlet UILabel* factionLabel;
@property IBOutlet MultiSelectSegmentedControl* factionControl;

@property IBOutlet UILabel* typeLabel;
@property IBOutlet MultiSelectSegmentedControl* typeControl;

@property NRRole role;
@property CardList* cardList;

@end
