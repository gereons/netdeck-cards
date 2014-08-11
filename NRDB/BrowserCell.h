//
//  BrowserCell.h
//  NRDB
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface BrowserCell : UITableViewCell

@property (nonatomic) Card* card;
@property IBOutlet UIButton* moreButton;

-(IBAction)moreClicked:(id)sender;

@end
