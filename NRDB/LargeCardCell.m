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
#import "SettingsKeys.h"
#import "ImageCache.h"

@interface LargeCardCell()
@property NSArray* pips;
@end
@implementation LargeCardCell

-(void) awakeFromNib
{
    [super awakeFromNib];
    
    self.pips = @[ self.pip1, self.pip2, self.pip3, self.pip4, self.pip5 ];
    
    static int diameter = 8;
    for (UIView* pip in self.pips)
    {
        pip.frame = CGRectSetSize(pip.frame, diameter, diameter);
        pip.layer.cornerRadius = diameter/2;
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
        self.name.text = [NSString stringWithFormat:@"%lu× %@ •", (unsigned long)cc.count, card.name];
    }
    else
    {
        self.name.text = [NSString stringWithFormat:@"%lu× %@", (unsigned long)cc.count, card.name];
    }
    
    self.name.textColor = [UIColor blackColor];
    if ([card.setCode isEqualToString:@"core"] && !self.deck.isDraft)
    {
        NSInteger cores = [[NSUserDefaults standardUserDefaults] integerForKey:NUM_CORES];
        NSInteger owned = cores * card.quantity;
        
        if (owned < cc.count)
        {
            self.name.textColor = [UIColor redColor];
        }
    }
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype)
    {
        self.type.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        self.type.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }
    
    NSUInteger influence = 0;
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
    self.identityButton.hidden = card.type != NRCardTypeIdentity;
    self.type.hidden = NO;
    
    // labels from top: cost/strength/mu
    switch (card.type)
    {
        case NRCardTypeIdentity:
            self.label1.text = [@(card.minimumDecksize) stringValue];
            self.icon1.image = [ImageCache cardIcon];
            if (card.influenceLimit == -1)
            {
                self.label2.text = @"∞";
            }
            else
            {
                self.label2.text = [@(card.influenceLimit) stringValue];
            }
            self.icon2.image = [ImageCache influenceIcon];
            if (card.role == NRRoleRunner)
            {
                self.label3.text = [NSString stringWithFormat:@"%d", card.baseLink];
                self.icon3.image = [ImageCache linkIcon];
            }
            else
            {
                self.label3.text = @"";
                self.icon3.image = nil;
            }
            if (cc == nil)
            {
                self.type.hidden = YES;
                self.label1.text = @"";
                self.label2.text = @"";
                self.label3.text = @"";
                self.icon1.image = nil;
                self.icon2.image = nil;
                self.icon3.image = nil;
                [self.identityButton setTitle:l10n(@"Choose Identity") forState:UIControlStateNormal];
            }
            else
            {
                [self.identityButton setTitle:l10n(@"Switch Identity") forState:UIControlStateNormal];
            }
            break;
            
        case NRCardTypeProgram:
        case NRCardTypeResource:
        case NRCardTypeEvent:
        case NRCardTypeHardware:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%d", card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = card.strength != -1 ? [NSString stringWithFormat:@"%d", card.strength] : @"";
            self.icon2.image = card.strength != -1 ? [ImageCache strengthIcon] : nil;
            self.label3.text = card.mu != -1 ? [NSString stringWithFormat:@"%d", card.mu] : @"";
            self.icon3.image = card.mu != -1 ? [ImageCache muIcon] : nil;
            break;
            
        case NRCardTypeIce:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%d", card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = card.strength != -1 ? [NSString stringWithFormat:@"%d", card.strength] : @"";
            self.icon3.image = card.strength != -1 ? [ImageCache strengthIcon] : nil;
            break;
            
        case NRCardTypeAgenda:
            self.label1.text = [NSString stringWithFormat:@"%d", card.advancementCost];
            self.icon1.image = [ImageCache difficultyIcon];
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = [NSString stringWithFormat:@"%d", card.agendaPoints];
            self.icon3.image = [ImageCache apIcon];
            break;
            
        case NRCardTypeAsset:
        case NRCardTypeOperation:
        case NRCardTypeUpgrade:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%d", card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = card.trash != -1 ? [NSString stringWithFormat:@"%d", card.trash] : @"";
            self.icon3.image = card.trash != -1 ? [ImageCache trashIcon] : nil;
            break;
            
        case NRCardTypeNone:
            NSAssert(NO, @"this can't happen");
            break;
    }
    
    self.copiesStepper.maximumValue = self.deck.isDraft ? 100 : cc.card.maxCopies;
    self.copiesStepper.value = cc.count;
    self.copiesLabel.text = [NSString stringWithFormat:@"×%lu", (unsigned long)cc.count];
}

-(void) setInfluence:(NSUInteger)influence
{
    if (influence > 0)
    {
        self.influenceLabel.textColor = self.cardCounter.card.factionColor;
        self.influenceLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)influence];
        
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
