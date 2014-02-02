//
//  SmallCardCell.m
//  NRDB
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "SmallCardCell.h"
#import "CardCounter.h"
#import "Deck.h"

@implementation SmallCardCell

-(void) setCardCounter:(CardCounter *)cc
{
    _cardCounter = cc;
    Card* card = cc.card;
    
    self.copiesStepper.maximumValue = cc.card.maxCopies;
    self.copiesStepper.value = cc.count;
    
    if (card.type == NRCardTypeIdentity)
    {
        self.name.text = card.name;
    }
    else if (card.unique)
    {
        self.name.text = [NSString stringWithFormat:@"%d× %@ •", cc.count, card.name];
    }
    else
    {
        self.name.text = [NSString stringWithFormat:@"%d× %@", cc.count, card.name];
    }
    
    int influence = 0;
    if (self.cardCounter.card.type == NRCardTypeAgenda)
    {
        influence = card.agendaPoints * cc.count;
    }
    else
    {
        if (self.deck)
        {
            influence = [self.deck influenceFor:cc];
        }
        else
        {
            influence = card.influence * cc.count;
        }
    }
    
    if (influence > 0)
    {
        self.influenceLabel.textColor = self.cardCounter.card.factionColor;
        self.influenceLabel.text = [NSString stringWithFormat:@"%d", influence];
    }
    else
    {
        self.influenceLabel.text = @"";
    }
}

@end