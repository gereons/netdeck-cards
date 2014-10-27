//
//  LargeBrowserCell.h
//  NRDB
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "BrowserCell.h"

@interface LargeBrowserCell : BrowserCell

@property IBOutlet UILabel* name;
@property IBOutlet UILabel* type;

@property IBOutlet UILabel* label1;
@property IBOutlet UILabel* label2;
@property IBOutlet UILabel* label3;
@property IBOutlet UIImageView* icon1;
@property IBOutlet UIImageView* icon2;
@property IBOutlet UIImageView* icon3;

@property IBOutlet UIView* pip1;
@property IBOutlet UIView* pip2;
@property IBOutlet UIView* pip3;
@property IBOutlet UIView* pip4;
@property IBOutlet UIView* pip5;

@end
