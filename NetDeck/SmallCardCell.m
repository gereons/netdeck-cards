//
//  SmallCardCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "SmallCardCell.h"
#import "CGRectUtils.h"

@implementation SmallCardCell

-(void) awakeFromNib
{
    self.name.font = [UIFont md_mediumSystemFontOfSize:17];
    
    NSInteger diameter = 8;
    self.mwlMarker.frame = CGRectSetSize(self.mwlMarker.frame, diameter, diameter);
    self.mwlMarker.layer.cornerRadius = diameter/2;
    self.mwlMarker.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.mwlMarker.layer.borderWidth = 1;
    self.mwlMarker.layer.borderColor = [UIColor blackColor].CGColor;
}

-(void) setCardCounter:(CardCounter *)cc
{
    [super setCardCounter:cc];
    Card* card = cc.card;
    
    self.copiesStepper.hidden = card.type == NRCardTypeIdentity;
    self.identityButton.hidden = card.type != NRCardTypeIdentity;
    self.factionLabel.hidden = card.type == NRCardTypeIdentity;
    
    if (cc == nil)
    {
        [self.identityButton setTitle:l10n(@"Choose Identity") forState:UIControlStateNormal];
    }
    else
    {
        [self.identityButton setTitle:l10n(@"Switch Identity") forState:UIControlStateNormal];
    }
    
    self.copiesStepper.maximumValue = self.deck.isDraft ? 100 : cc.card.maxPerDeck;
    self.copiesStepper.value = cc.count;
    
    if (card.type == NRCardTypeIdentity)
    {
        self.name.text = card.name;
    }
    else if (card.unique)
    {
        self.name.text = [NSString stringWithFormat:@"%lu× %@ •", (unsigned long)cc.count, card.name];
    }
    else
    {
        self.name.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cc.count, card.name];
    }
    
    self.name.textColor = [UIColor blackColor];
    if (!self.deck.isDraft && card.owned < cc.count)
    {
        self.name.textColor = [UIColor redColor];
    }
    
    NSUInteger influence = 0;
    if (card.type == NRCardTypeAgenda)
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
        self.influenceLabel.textColor = card.factionColor;
        self.influenceLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)influence];
    }
    else
    {
        self.influenceLabel.text = @"";
    }
    
    self.mwlMarker.hidden = !card.isMostWanted;
    self.factionLabel.text = card.factionStr;
}

@end
