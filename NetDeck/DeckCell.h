//
//  DeckCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 13.04.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface DeckCell : UITableViewCell

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* identityLabel;
@property IBOutlet UILabel* summaryLabel;
@property IBOutlet UILabel* dateLabel;
@property IBOutlet UIButton* infoButton;
@property IBOutlet UIImageView* nrdbIcon;

@end
