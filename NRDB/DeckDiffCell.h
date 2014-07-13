//
//  DeckDiffCell.h
//  NRDB
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeckDiffCell : UITableViewCell

@property IBOutlet UILabel* deck1Card;
@property IBOutlet UILabel* deck2Card;
@property IBOutlet UILabel* diff;

@end
