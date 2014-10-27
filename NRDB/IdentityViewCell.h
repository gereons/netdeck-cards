//
//  IdentityViewCell.h
//  NRDB
//
//  Created by Gereon Steffens on 27.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@interface IdentityViewCell : UITableViewCell

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UILabel* deckSizeLabel;
@property IBOutlet UILabel* influenceLimitLabel;
@property IBOutlet UILabel* linkLabel;

@property IBOutlet UIImageView* deckSizeIcon;
@property IBOutlet UIImageView* influenceIcon;
@property IBOutlet UIImageView* linkIcon;

@property IBOutlet UIButton* infoButton;

@end
