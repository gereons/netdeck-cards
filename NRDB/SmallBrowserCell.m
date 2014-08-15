//
//  SmallBrowserCell.m
//  NRDB
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "SmallBrowserCell.h"
#import "Card.h"
#import "Faction.h"

@implementation SmallBrowserCell

- (void)awakeFromNib
{
    self.pips = [SmallPipsView createWithFrame:CGRectMake(10, 3, 38, 38)];
    
    [self.contentView addSubview:self.pips];
}

-(void) setCard:(Card *)card
{
    [super setCard:card];
    self.nameLabel.text = card.name;
        
    [self.pips setValue:card.type == NRCardTypeAgenda ? card.agendaPoints : card.influence];
    [self.pips setColor:card.factionColor];
}

@end