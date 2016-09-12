//
//  CardFilterCell.h
//  NetDeck
//
//  Created by Gereon Steffens on 12.09.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SmallPipsView.h"

@interface CardFilterCell : UITableViewCell

@property IBOutlet UIButton* addButton;
@property IBOutlet UIView* pipsView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* countLabel;

@property SmallPipsView* pips;

@end
