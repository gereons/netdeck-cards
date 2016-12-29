//
//  IdentityViewCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 27.12.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "IdentityViewCell.h"

@implementation IdentityViewCell

-(void) awakeFromNib {
    [super awakeFromNib];
    
    UIFont* font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.deckSizeLabel.font = font;
    self.influenceLimitLabel.font = font;
    self.linkLabel.font = font;
}
@end
