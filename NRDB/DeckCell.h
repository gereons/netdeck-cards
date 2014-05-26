//
//  DeckCell.h
//  NRDB
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeckCell : UITableViewCell

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* identityLabel;
@property IBOutlet UILabel* summaryLabel;
@property IBOutlet UILabel* dateLabel;
@property IBOutlet UIButton* infoButton;

@end
