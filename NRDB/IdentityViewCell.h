//
//  IdentityViewCell.h
//  NRDB
//
//  Created by Gereon Steffens on 27.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IdentityViewCell : UITableViewCell

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UILabel* abilityLabel;
@property IBOutlet UILabel* deckSizeLabel;
@property IBOutlet UILabel* influenceLimitLabel;

@end
