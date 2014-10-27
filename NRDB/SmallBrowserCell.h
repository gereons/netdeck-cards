//
//  SmallBrowserCell.h
//  NRDB
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "BrowserCell.h"
#import "SmallPipsView.h"

@interface SmallBrowserCell : BrowserCell

@property IBOutlet UILabel* nameLabel;

@property SmallPipsView* pips;

@end
