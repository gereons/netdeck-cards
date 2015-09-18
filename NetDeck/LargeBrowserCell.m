//
//  LargeBrowserCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "LargeBrowserCell.h"
#import "CGRectUtils.h"
#import "Card.h"
#import "Faction.h"
#import "CardType.h"
#import "ImageCache.h"

@interface LargeBrowserCell()

@property NSArray* pips;

@end

@implementation LargeBrowserCell

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

-(void) setCard:(Card*)card
{
    [super setCard:card];

    if (card.unique)
    {
        self.name.text = [NSString stringWithFormat:@"%@ •", card.name];
    }
    else
    {
        self.name.text = card.name;
    }
    
    self.name.textColor = [UIColor blackColor];
    
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
    
    NSInteger influence = 0;
    if (card.type == NRCardTypeAgenda)
    {
        influence = card.agendaPoints;
    }
    else
    {
        influence = card.influence;
    }
    [self setInfluence:influence withColor:card.factionColor];
    
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
}

-(void) setInfluence:(NSInteger)influence withColor:(UIColor*)color
{
    if (influence > 0)
    {
        for (int i=0; i<self.pips.count; ++i)
        {
            UIView* pip = self.pips[i];
            pip.layer.backgroundColor = [color CGColor];
            pip.hidden = i >= influence;
            // NSLog(@"%d %d", i, pip.hidden);
        }
    }
    else
    {
        for (UIView* pip in self.pips)
        {
            pip.hidden = YES;
        }
    }
}

@end
