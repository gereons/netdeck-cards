//
//  LargeCardCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "LargeCardCell.h"
#import "CGRectUtils.h"

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
    
    self.name.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightMedium];
    
    for (UILabel* lbl in @[ self.label1, self.label2, self.label3]) {
        lbl.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightRegular];
    }
}

-(void) prepareForReuse {
    for (UIView* pip in self.pips) {
        pip.layer.borderWidth = 0;
    }
}

-(void) setCardCounter:(CardCounter *)cc
{
    [super setCardCounter:cc];
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
    if (!self.deck.isDraft && card.owned < cc.count)
    {
        self.name.textColor = [UIColor redColor];
    }
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    
    NSString* subtype = card.subtype;
    if (subtype.length > 0)
    {
        self.type.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        self.type.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }

    if (self.deck) {
        [self setInfluence:[self.deck influenceFor:cc] andCard:cc];
    } else {
        [self setInfluence:card.influence andCard:cc];
    }
    
    self.copiesLabel.hidden = card.type == NRCardTypeIdentity;
    self.copiesStepper.hidden = card.type == NRCardTypeIdentity;
    self.identityButton.hidden = card.type != NRCardTypeIdentity;
    self.type.hidden = NO;
    
    self.label2.textColor = [UIColor blackColor];
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
                NSInteger inf = self.deck.influenceLimit;
                self.label2.text = [NSString stringWithFormat:@"%ld", (long)inf];
                if (inf != card.influenceLimit) {
                    self.label2.textColor = [UIColor redColor];
                }
            }
            self.icon2.image = [ImageCache influenceIcon];
            if (card.role == NRRoleRunner)
            {
                self.label3.text = [NSString stringWithFormat:@"%ld", (long)card.baseLink];
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
        case NRCardTypeHardware: {
            NSString* cost = card.costString;
            NSString* str = card.strengthString;
            self.label1.text = cost;
            self.icon1.image = cost.length > 0 ? [ImageCache creditIcon] : nil;
            self.label2.text = str;
            self.icon2.image = str.length > 0 ? [ImageCache strengthIcon] : nil;
            self.label3.text = card.mu != -1 ? [NSString stringWithFormat:@"%ld", (long)card.mu] : @"";
            self.icon3.image = card.mu != -1 ? [ImageCache muIcon] : nil;
            break;
        }
            
        case NRCardTypeIce: {
            NSString* cost = card.costString;
            NSString* str = card.strengthString;
            self.label1.text = cost;
            self.icon1.image = cost.length > 0 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = str;
            self.icon3.image = str.length > 0 ? [ImageCache strengthIcon] : nil;
            break;
        }
            
        case NRCardTypeAgenda:
            self.label1.text = [NSString stringWithFormat:@"%ld", (long)card.advancementCost];
            self.icon1.image = [ImageCache difficultyIcon];
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = [NSString stringWithFormat:@"%ld", (long)card.agendaPoints];
            self.icon3.image = [ImageCache apIcon];
            break;
            
        case NRCardTypeAsset:
        case NRCardTypeOperation:
        case NRCardTypeUpgrade: {
            NSString* cost = card.costString;
            self.label1.text = cost;
            self.icon1.image = cost.length > 0 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = card.trash != -1 ? [NSString stringWithFormat:@"%ld", (long)card.trash] : @"";
            self.icon3.image = card.trash != -1 ? [ImageCache trashIcon] : nil;
            break;
        }
            
        case NRCardTypeNone:
            NSAssert(NO, @"this can't happen");
            break;
    }
    
    self.copiesStepper.maximumValue = self.deck.isDraft ? 100 : cc.card.maxPerDeck;
    self.copiesStepper.value = cc.count;
    self.copiesLabel.text = [NSString stringWithFormat:@"×%lu", (unsigned long)cc.count];
}

-(void) setInfluence:(NSInteger)influence andCard:(CardCounter*)cc
{
    if (influence > 0)
    {
        self.influenceLabel.textColor = cc.card.factionColor;
        self.influenceLabel.text = [NSString stringWithFormat:@"%ld", (long)influence];
        
        CGColorRef color = cc.card.factionColor.CGColor;
        
        for (int i=0; i<self.pips.count; ++i)
        {
            UIView* pip = self.pips[i];
            pip.layer.backgroundColor = color;
            pip.hidden = i >= cc.card.influence;
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
    
    if (cc.card.isMostWanted) {
        for (UIView* pip in self.pips) {
            // find the first non-hidden pip, and draw it as a black circle
            if (!pip.hidden) {
                continue;
            }
            
            pip.layer.backgroundColor = [UIColor whiteColor].CGColor;
            pip.layer.borderWidth = 1;
            pip.layer.borderColor = [UIColor blackColor].CGColor;
            pip.hidden = NO;
            break;
        }
    }
}

@end
