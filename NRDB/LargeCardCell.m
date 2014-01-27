//
//  CardCell.m
//  NRDB
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"
#import "CardCounter.h"
#import "Faction.h"
#import "CardType.h"
#import "CGRectUtils.h"
#import "Notifications.h"

@interface CardCell()
@property NSArray* pips;
@end
@implementation CardCell

-(void) awakeFromNib
{
    self.pips = @[ self.pip1, self.pip2, self.pip3, self.pip4, self.pip5 ];
    
    for (UIView*pip in self.pips)
    {
        pip.layer.cornerRadius = 6;
        pip.layer.shadowRadius = 1;
        pip.layer.shadowOffset = CGSizeMake(1,1);
        pip.layer.shadowOpacity = .3;
        pip.layer.shadowColor = [UIColor blackColor].CGColor;
    }
}

-(void) copiesChanged:(UIStepper*)sender
{
    int copies = sender.value;
    self.cardCounter.count = copies;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
}

-(void) setCardCounter:(CardCounter *)cardCounter
{
    self->_cardCounter = cardCounter;
    self.copiesStepper.value = cardCounter.count;
}

-(void) setInfluence:(int)influence
{
    if (influence > 0)
    {
        self.influenceLabel.textColor = self.cardCounter.card.factionColor;
        self.influenceLabel.text = [NSString stringWithFormat:@"%d", influence];
        
        CGColorRef color = self.cardCounter.card.factionColor.CGColor;
        
        for (int i=0; i<self.pips.count; ++i)
        {
            UIView* pip = self.pips[i];
            pip.layer.backgroundColor = color;
            pip.hidden = i >= self.cardCounter.card.influence;
        }
    }
    else
    {
        self.influenceLabel.text = @"";
        for (UIView* pip in self.pips)
        {
            pip.hidden = YES;
        }
    }
}

@end
