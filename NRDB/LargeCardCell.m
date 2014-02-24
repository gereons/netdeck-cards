//
//  LargeCardCell.m
//  NRDB
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "LargeCardCell.h"
#import "CardCounter.h"
#import "Deck.h"
#import "Faction.h"
#import "CardType.h"
#import "CGRectUtils.h"
#import "Notifications.h"

@interface LargeCardCell()
@property NSArray* pips;
@end
@implementation LargeCardCell

-(void) awakeFromNib
{
    self.pips = @[ self.pip1, self.pip2, self.pip3, self.pip4, self.pip5 ];
    
    for (UIView*pip in self.pips)
    {
        pip.layer.cornerRadius = 6;
    }
}

-(void) setCardCounter:(CardCounter *)cc
{
    _cardCounter = cc;
    
    Card* card = cc.card;
    
    if (card.type == NRCardTypeIdentity)
    {
        self.name.text = card.name;
    }
    else if (card.unique)
    {
        self.name.text = [NSString stringWithFormat:@"%@ • ×%d", card.name, cc.count];
    }
    else
    {
        self.name.text = [NSString stringWithFormat:@"%@ ×%d", card.name, cc.count];
    }
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        self.type.text = [NSString stringWithFormat:@"%@ %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        self.type.text = [NSString stringWithFormat:@"%@ %@", factionName, typeName];
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
    [self setInfluence:influence];
    
    self.copiesLabel.hidden = card.type == NRCardTypeIdentity;
    self.copiesStepper.hidden = card.type == NRCardTypeIdentity;
    
    // labels from top: cost/strength/mu
    switch (card.type)
    {
        case NRCardTypeIdentity:
            self.cost.text = [@(card.minimumDecksize) stringValue];
            self.strength.text = [@(card.influenceLimit) stringValue];
            if (card.role == NRRoleRunner)
            {
                self.mu.text = [NSString stringWithFormat:@"%d Link", card.baseLink];
            }
            else
            {
                self.mu.text = @"";
            }
            break;
            
        case NRCardTypeProgram:
        case NRCardTypeResource:
        case NRCardTypeEvent:
        case NRCardTypeHardware:
        case NRCardTypeIce:
            self.cost.text = card.cost != -1 ? [NSString stringWithFormat:@"%d Cr", card.cost] : @"";
            self.strength.text = card.strength != -1 ? [NSString stringWithFormat:@"%d Str", card.strength] : @"";
            self.mu.text = card.mu != -1 ? [NSString stringWithFormat:@"%d Str", card.mu] : @"";
            break;
            
        case NRCardTypeAgenda:
            self.cost.text = [NSString stringWithFormat:@"%d Adv", card.advancementCost];
            self.strength.text = [NSString stringWithFormat:@"%d AP", card.agendaPoints];
            self.mu.text = @"";
            break;
            
        case NRCardTypeAsset:
        case NRCardTypeOperation:
        case NRCardTypeUpgrade:
            self.cost.text = card.cost != -1 ? [NSString stringWithFormat:@"%d Cr", card.cost] : @"";
            self.strength.text = card.trash != -1 ? [NSString stringWithFormat:@"%d Tr", card.trash] : @"";
            self.mu.text = @"";
            break;
            
        case NRCardTypeNone:
            NSAssert(NO, @"this can't happen");
            break;
    }
    
    self.copiesStepper.maximumValue = cc.card.maxCopies;
    self.copiesStepper.value = cc.count;
    self.copiesLabel.text = [NSString stringWithFormat:@"×%d", cc.count];
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
