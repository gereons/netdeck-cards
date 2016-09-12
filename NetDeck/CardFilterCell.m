//
//  CardFilterCell.m
//  NetDeck
//
//  Created by Gereon Steffens on 12.09.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardFilterCell.h"

@implementation CardFilterCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.pips = [SmallPipsView createWithFrame:CGRectMake(0, 0, 38, 38)];
    [self.pipsView addSubview:self.pips];
}


@end
