//
//  SmallBrowserCell.h
//  NRDB
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SmallPipsView.h"

@interface SmallBrowserCell : UITableViewCell

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* typeLabel;
@property SmallPipsView* pips;

@end
