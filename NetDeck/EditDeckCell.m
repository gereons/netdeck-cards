//
//  EditDeckCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "EditDeckCell.h"

@implementation EditDeckCell

-(void) awakeFromNib
{
    [super awakeFromNib];
    
    self.accessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.influenceLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightRegular];
    self.mwlLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
}

-(void) prepareForReuse {
    self.influenceLabel.textColor = [UIColor blackColor];
}

@end
