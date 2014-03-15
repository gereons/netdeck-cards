//
//  Card.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Card.h"
#import "CardData.h"
#import <DTCoreText.h>

@interface Card()

@property CardData* data;
@property NSString* filteredText;
@property NSAttributedString* attributedText;
@property CGFloat attributedTextHeight;

@end

@implementation Card

#define PROPERTY_PROXY(type, attr) -(type)attr { return self.data.attr; }

PROPERTY_PROXY(NSString*, code)
PROPERTY_PROXY(NSString*, name)
PROPERTY_PROXY(NSString*, text)
PROPERTY_PROXY(NSString*, flavor)
PROPERTY_PROXY(NSString*, typeStr)
PROPERTY_PROXY(NSString*, subtype)
PROPERTY_PROXY(NSArray*, subtypes)
PROPERTY_PROXY(NRCardType, type)
PROPERTY_PROXY(NRFaction, faction)
PROPERTY_PROXY(NSString*, factionStr)
PROPERTY_PROXY(NRRole, role)
PROPERTY_PROXY(int, influenceLimit)
PROPERTY_PROXY(int, minimumDecksize)
PROPERTY_PROXY(int, baseLink)
PROPERTY_PROXY(int, influence)
PROPERTY_PROXY(int, cost)
PROPERTY_PROXY(int, strength)
PROPERTY_PROXY(int, mu)
PROPERTY_PROXY(NSString*, setName)
PROPERTY_PROXY(NSString*, setCode)
PROPERTY_PROXY(NSString*, artist)
PROPERTY_PROXY(int, trash)
PROPERTY_PROXY(int, quantity)
PROPERTY_PROXY(BOOL, unique)
PROPERTY_PROXY(NSString*, imageSrc)
PROPERTY_PROXY(int, advancementCost)
PROPERTY_PROXY(int, agendaPoints)
PROPERTY_PROXY(NSString*, url)
PROPERTY_PROXY(int, maxCopies)

static NSMutableArray* allRunnerCards;
static NSMutableArray* allCorpCards;
static NSMutableArray* allRunnerIdentities;
static NSMutableArray* allCorpIdentities;

-(id) initWithData:(CardData*)data
{
    if ((self = [super init]))
    {
        self.data = data;
    }
    return self;
}

+(Card*) cardByCode:(NSString*)code
{
    CardData* cd = [CardData cardByCode:code];
    if (cd == nil)
    {
        return nil;
    }
    
    Card* card = [Card new];
    card.data = cd;
    return card;
}

+(NSArray*) allCards
{
    NSMutableArray* cards = [NSMutableArray array];
    [cards addObjectsFromArray:[Card allForRole:NRRoleRunner]];
    [cards addObjectsFromArray:[Card allForRole:NRRoleCorp]];
    [cards addObjectsFromArray:[Card identitiesForRole:NRRoleRunner]];
    [cards addObjectsFromArray:[Card identitiesForRole:NRRoleCorp]];
    
    return [cards sortedArrayUsingComparator:^(Card* c1, Card *c2) {
        NSUInteger l1 = c1.name.length;
        NSUInteger l2 = c2.name.length;
        if (l1 > l2)
        {
            return NSOrderedAscending;
        }
        else if (l1 < l2)
        {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

+(NSArray*) altCards
{
    NSMutableArray* altCards = [NSMutableArray array];
    for (CardData* cd in [CardData altCards])
    {
        Card* card = [[Card alloc] initWithData:cd];
        [altCards addObject:card];
    }
    return altCards;
}

+(NSArray*) allForRole:(NRRole)role
{
    NSMutableArray* arr;
    @synchronized(self)
    {
        arr = role == NRRoleRunner ? allRunnerCards : allCorpCards;
        if (!arr)
        {
            arr = [NSMutableArray array];
            NSArray* src = role == NRRoleRunner ? [CardData allRunnerCards] : [CardData allCorpCards];
            for (CardData* cd in src)
            {
                Card* card = [[Card alloc] initWithData:cd];
                [arr addObject:card];
            }
        }
    }
    return arr;
}

+(NSArray*) identitiesForRole:(NRRole)role
{
    NSMutableArray* arr = role == NRRoleRunner ? allRunnerIdentities : allCorpIdentities;
    
    if (!arr)
    {
        arr = [NSMutableArray array];
        for (CardData*cd in [CardData identitiesForRole:role])
        {
            Card* card = [[Card alloc] initWithData:cd];
            [arr addObject:card];
        }
    }
    return arr;
}

-(NSString*) detailText
{
    NSString *s = self.typeStr;
    
    if (self.subtype)
    {
        s = [s stringByAppendingFormat:@" (%@)", self.subtype];
    }
    
    if (self.type == NRCardTypeProgram)
    {
        s = [s stringByAppendingFormat:@" - %d MU", self.mu];
    }
    if (self.cost != -1)
    {
        s = [s stringByAppendingFormat:@" - Cost %d", self.cost];
    }
    if (self.strength != -1)
    {
        s = [s stringByAppendingFormat:@" - Str %d", self.strength];
    }
    if (self.trash != -1)
    {
        s = [s stringByAppendingFormat:@" - Trash %d", self.trash];
    }
    if (self.influence != -1)
    {
        s = [s stringByAppendingFormat:@" - Inf %d", self.influence];
    }
    if (self.unique)
    {
        s = [s stringByAppendingFormat:@" - Unique"];
    }
    
    s = [s stringByAppendingFormat:@" (%@)", [self.setCode uppercaseString]];
    
    return s;
}

-(NSString*) filteredText
{
    if (!self->_filteredText)
    {
        NSString *str = [self.text stringByReplacingOccurrencesOfString:@"<strong>" withString:@""];
        self->_filteredText = [str stringByReplacingOccurrencesOfString:@"</strong>" withString:@""];
    }
    return self->_filteredText;
}

-(NSAttributedString*) attributedText
{
    if (!self->_attributedText)
    {
        NSString *str = [self.text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        
        NSAttributedString* attrStr = [[NSAttributedString alloc] initWithHTMLData:data
                                                                              options: @{ DTUseiOS6Attributes: @(YES),
                                                                                          DTDefaultFontFamily: @"Helvetica",
                                                                                          DTDefaultFontSize: @(13)
                                                                                          }
                                                                   documentAttributes:NULL];
        
        CGSize bounds = CGSizeMake(417, 1000);
        CGRect textRect = [attrStr boundingRectWithSize:bounds
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                 context:nil];
        
        self->_attributedText = attrStr;
        self->_attributedTextHeight = ceilf(textRect.size.height) + 15.0; // wtf?
    }
    return self->_attributedText;
}

-(CGFloat) attributedTextHeight
{
    if (!self->_attributedText)
    {
        NSAttributedString* s = self.attributedText;
        (void)s;
    }
    return self->_attributedTextHeight;
}

-(NSString*) octgnCode
{
    return [NSString stringWithFormat:@"bc0f047c-01b1-427f-a439-d451eda%@", self.code];
}

-(Card*) altCard
{
    CardData* alt = [CardData altFor:self.name];
    if (alt)
    {
        Card* card = [[Card alloc] initWithData:alt];
        return card;
    }
    return nil;
}

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

-(NSUInteger) factionHexColor
{
    switch (self.faction)
    {
        case NRFactionJinteki:      return 0xc62026;
        case NRFactionNBN:          return 0xd7a32d;
        case NRFactionWeyland:      return 0x2d7868;
        case NRFactionHaasBioroid:  return 0x6b2b8a;
        case NRFactionShaper:       return 0x6ab545;
        case NRFactionCriminal:     return 0x4f67b0;
        case NRFactionAnarch:       return 0xf47c28;
        default: return 0;
    }
}

-(UIColor*) factionColor
{
    NSUInteger rgb = [self factionHexColor];
    return UIColorFromRGB(rgb);
}

-(BOOL) isEqual:(id)object
{
    Card* other = (Card*)object;
    return [self.code isEqualToString:other.code];
}

- (NSUInteger)hash
{
    return self.code.hash;
}

@end