//
//  SmallBrowserCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "SmallBrowserCell.h"

@implementation SmallBrowserCell

- (void)awakeFromNib
{
    self.pips = [SmallPipsView createWithFrame:CGRectMake(10, 3, 38, 38)];
    
    [self.contentView addSubview:self.pips];
}

-(void) setCard:(Card *)card
{
    [super setCard:card];
    if (card.unique)
    {
        self.nameLabel.text = [NSString stringWithFormat:@"%@ •", card.name];
    }
    else
    {
        self.nameLabel.text = card.name;
    }
    
    [self.pips setValue:card.type == NRCardTypeAgenda ? card.agendaPoints : card.influence];
    [self.pips setColor:card.factionColor];
    self.factionLabel.text = card.factionStr;
}

@end
