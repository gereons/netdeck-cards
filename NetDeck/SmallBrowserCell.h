//
//  SmallBrowserCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "BrowserCell.h"
#import "SmallPipsView.h"

@interface SmallBrowserCell : BrowserCell

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* factionLabel;
@property IBOutlet UIView* pipsView;

@property SmallPipsView* pips;

@end
