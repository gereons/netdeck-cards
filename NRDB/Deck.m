//
//  Deck.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Deck.h"

#import "Card.h"
#import "CardCounter.h"

@interface Deck()
{
    NSMutableArray* _cards; // array of CardCounter
}

@end

@implementation Deck

-(Deck*) init
{
    if ((self = [super init]))
    {
        self->_cards = [NSMutableArray array];
    }
    return self;
}

-(Card*) identity
{
    return self.identityCc.card;
}

-(void) setIdentity:(Card *)identity
{
    if (identity)
    {
        self.identityCc = [CardCounter initWithCard:identity andCount:1];
        self.role = identity.role;
    }
    else
    {
        self.identityCc = nil;
    }
}

-(NSArray*) cards
{
    return self->_cards;
}

-(NSArray*) allCards
{
    NSMutableArray* arr = [NSMutableArray array];
    if (self.identityCc)
    {
        [arr addObject:self.identityCc];
    }
    [arr addObjectsFromArray:self.cards];
    return arr;
}

-(NSArray*) checkValidity
{
    NSMutableArray* reasons = [NSMutableArray array];
    if (self.identityCc == nil)
    {
        [reasons addObject:l10n(@"No Identity")];
    }
    else
    {
        NSAssert(self.identityCc.count == 1, @"identity count");
    }
    
    if (self.influence > self.identity.influenceLimit)
    {
        [reasons addObject:l10n(@"Too much influence used")];
    }
    
    if (self.size < self.identity.minimumDecksize)
    {
        [reasons addObject:l10n(@"Not enough cards")];
    }
    
    if (self.identity.role == NRRoleCorp)
    {
        // check agenda points
        int apRequired = ((self.size / 5) + 1) * 2;
        if (self.agendaPoints != apRequired && self.agendaPoints != apRequired+1)
        {
            [reasons addObject:[NSString stringWithFormat:l10n(@"AP must be %d or %d"), apRequired, apRequired+1]];
        }
    
        BOOL noJinteki = [self.identity.code isEqualToString:CUSTOM_BIOTICS];
        
        BOOL petError = NO, jintekiError = NO, agendaError = NO;
        
        // check dir. haas, custom biotics and out-of-faction agendas
        for (CardCounter* cc in self.cards)
        {
            Card* card = cc.card;
            if ([card.code isEqualToString:DIR_HAAS_PET_PROJ] && cc.count > 1 && !petError)
            {
                petError = YES;
                [reasons addObject:l10n(@"Too many pet projects")];
            }
            
            if (noJinteki && card.faction == NRFactionJinteki && !jintekiError)
            {
                jintekiError = YES;
                [reasons addObject:l10n(@"Cannot include Jinteki")];
            }
            
            if (card.type == NRCardTypeAgenda && card.faction != NRFactionNeutral && card.faction != self.identity.faction && !agendaError)
            {
                agendaError = YES;
                [reasons addObject:l10n(@"Cannot use out-of-faction agendas")];
            }
        }
    }
    
    return reasons;
}

-(int) size
{
    int sz = 0;
    for (CardCounter* cc in _cards)
    {
        sz += cc.count;
    }
    return sz;
}

-(int) agendaPoints
{
    int ap = 0;
    
    for (CardCounter* cc in _cards)
    {
        if (cc.card.type == NRCardTypeAgenda)
        {
            NSAssert(cc.count > 0 && cc.count < 4, @"invalid card count");
            ap += cc.card.agendaPoints * cc.count;
        }
    }
    return ap;
}

-(int) influence
{
    int inf = 0;
    BOOL isProfessor = [self.identity.code isEqualToString:THE_PROFESSOR];
    
    for (CardCounter* cc in _cards)
    {
        if (cc.card.faction != self.identity.faction && cc.card.influence != -1)
        {
            int count = cc.count;
            NSAssert(count > 0 && count < 4, @"invalid card count");
            
            if (isProfessor && cc.card.type == NRCardTypeProgram)
            {
                --count;
            }
            
            inf += cc.card.influence * count;
        }
    }
    return inf;
}

-(int) influenceFor:(CardCounter *)cc
{
    if (self.identity.faction == cc.card.faction || cc.card.influence == -1)
    {
        return 0;
    }
    
    int count = cc.count;
    NSAssert(count > 0 && count < 4, @"invalid card count");
    if (cc.card.type == NRCardTypeProgram && [self.identity.code isEqualToString:THE_PROFESSOR])
    {
        --count;
    }
    
    return count * cc.card.influence;
}

-(void) addCard:(Card *)card copies:(int)copies
{
    NSAssert(copies > 0 && copies < 4, @"invalid card count");
    NSAssert(card.type != NRCardTypeIdentity, @"can't add identity");
    
    int index = [self indexOfCard:card];
    if (index == -1)
    {
        CardCounter* cc = [CardCounter initWithCard:card andCount:copies];
        [_cards addObject:cc];
    }
    else
    {
        CardCounter* cc = [_cards objectAtIndex:index];
        int max = cc.card.maxCopies;
        if (cc.count < max)
        {
            cc.count = MIN(max, cc.count + copies);
        }
    }
    [self sort];
}

-(void) removeCard:(Card *)card
{
    [self removeCard:card copies:-1];
}

-(void) removeCard:(Card *)card copies:(int)copies
{
    NSAssert(card.type != NRCardTypeIdentity, @"can't remove identity");
    int index = [self indexOfCard:card];
    NSAssert(index != -1, @"removing card %@, not in deck", card.name);
    
    CardCounter* c = [_cards objectAtIndex:index];
    if (copies == -1 || copies >= c.count)
    {
        [_cards removeObjectAtIndex:index];
    }
    else
    {
        c.count -= copies;
    }
}

-(Deck*) duplicate
{
    Deck* newDeck = [Deck new];
    
    newDeck.name = [NSString stringWithFormat:l10n(@"Copy of %@"), self.name];
    newDeck.identityCc = self.identityCc;
    newDeck->_cards = [NSMutableArray arrayWithArray:_cards];
    newDeck->_role = self.role;
    newDeck.filename = nil;
    
    return newDeck;
}

-(int) indexOfCard:(Card*) card
{
    for (int i=0; i<_cards.count; ++i)
    {
        CardCounter* cc = _cards[i];
        if (cc.card.code == card.code)
        {
            return i;
        }
    }
    return -1;
}

-(CardCounter*) findCard:(Card*) card
{
    for (int i=0; i<_cards.count; ++i)
    {
        CardCounter* cc = _cards[i];
        if (cc.card.code == card.code)
        {
            return cc;
        }
    }
    return nil;
}

-(void) sort
{
    [_cards sortUsingComparator:^NSComparisonResult(CardCounter* c1, CardCounter* c2) {
        if (c1.card.type > c2.card.type)
        {
            return NSOrderedDescending;
        }
        else if (c1.card.type < c2.card.type)
        {
            return NSOrderedAscending;
        }
        else
        {
            return [c1.card.name localizedCaseInsensitiveCompare:c2.card.name];
        }
    }];
}

-(TableData*) dataForTableView
{
    NSMutableArray* sections = [NSMutableArray array];
    NSMutableArray* cards = [NSMutableArray array];
    
    [self sort];
    
    if (self.identityCc)
    {
        [sections addObject:self.identityCc.card.typeStr];
        [cards addObject:@[ self.identityCc ]];
    }
    else
    {
        // if there is no identity, get the typeStr of a known one and return a NSNull instance in its place
        Card* dummyId = [Card cardByCode:ANDROMEDA];
        [sections addObject:dummyId.typeStr];
        [cards addObject:@[ [NSNull null] ]];
    }
    
    // delete all cards with count==0
    NSMutableArray* removals = [NSMutableArray array];
    for (CardCounter* cc in self.cards)
    {
        if (cc.count == 0)
        {
            [removals addObject:cc.card];
        }
    }
    for (Card* card in removals)
    {
        [self removeCard:card];
    }
    
    NRCardType prevType = NRCardTypeNone;
    NSMutableArray* arr;
    for (CardCounter* cc in self.cards)
    {
        if (cc.card.type != prevType)
        {
            [sections addObject:cc.card.typeStr];
            if (arr != nil)
            {
                [cards addObject:arr];
            }
            arr = [NSMutableArray array];
        }
        [arr addObject:cc];
        prevType = cc.card.type;
    }
    
    if (arr.count > 0)
    {
        [cards addObject:arr];
    }
    
    NSAssert(sections.count == cards.count, @"count mismatch");
    
    return [[TableData alloc] initWithSections:sections andValues:cards];
}

#pragma mark NSCoding
-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        _cards = [decoder decodeObjectForKey:@"cards"];
        _name = [decoder decodeObjectForKey:@"name"];
        _role = [decoder decodeIntForKey:@"role"];
        NSString* identityCode = [decoder decodeObjectForKey:@"identity"];
        Card* identity = [Card cardByCode:identityCode];
        if (identity)
        {
            _identityCc = [CardCounter initWithCard:identity andCount:1];
        }
        _identityCc.showAltArt = [decoder decodeBoolForKey:@"identityAltArt"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.cards forKey:@"cards"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInt:self.role forKey:@"role"];
    [coder encodeObject:self.identity.code forKey:@"identity"];
    [coder encodeBool:self.identityCc.showAltArt forKey:@"identityAltArt"];
}


@end
