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
    self.accessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.influenceLabel.font = [UIFont md_systemFontOfSize:15];
    self.mwlLabel.font = [UIFont md_systemFontOfSize:13];
}

-(void) prepareForReuse {
    self.influenceLabel.textColor = [UIColor blackColor];
}

@end
