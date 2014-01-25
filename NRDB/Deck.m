//
//  Deck.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
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

-(NSArray*) cards
{
    return self->_cards;
}

-(BOOL) valid:(NSString**)reason
{
    if (self.identity == nil)
    {
        *reason = @"No Identity selected";
        return NO;
    }
    
    if (self.identity.role == NRRoleCorp)
    {
        // check agenda points
        int apRequired = ((self.size / 5) + 1) * 2;
        if (self.agendaPoints != apRequired && self.agendaPoints != apRequired+1)
        {
            *reason = [NSString stringWithFormat:@"Must have %d or %d Agenda Points", apRequired, apRequired+1];
            return NO;
        }
    
        BOOL noJinteki = [self.identity.code isEqualToString:CUSTOM_BIOTICS];
        
        // check dir. haas, custom biotics and out-of-faction agendas
        for (CardCounter* cc in self.cards)
        {
            Card* card = cc.card;
            if ([card.code isEqualToString:DIR_HAAS_PET_PROJ] && cc.count > 1)
            {
                *reason = @"Too many pet projects";
                return NO;
            }
            
            if (noJinteki && card.faction == NRFactionJinteki)
            {
                *reason = @"Cannot include Jinteki";
                return NO;
            }
            
            if (card.type == NRCardTypeAgenda && card.faction != NRFactionNeutral && card.faction != self.identity.faction)
            {
                *reason = @"Cannot use out-of-faction agendas";
                return NO;
            }
        }
    }
    
    if (self.size < self.identity.minimumDecksize)
    {
        *reason = @"Not enough cards";
        return NO;
    }
    if (self.influence > self.identity.influenceLimit)
    {
        *reason = @"Too much influence used";
        return NO;
    }

    return YES;
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

-(int) influenceFor:(CardCounter *)cc
{
    if (self.identity.faction == cc.card.faction)
    {
        return 0;
    }
    
    int count = cc.count;
    if (cc.card.type == NRCardTypeProgram && [self.identity.code isEqualToString:THE_PROFESSOR])
    {
        --count;
    }
    
    return count * cc.card.influence;
}

-(void) addCard:(Card *)card copies:(int)copies
{
    NSAssert(copies > 0 && copies < 4, @"invalid card count");
    
    int index = [self findCard:card];
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
    int index = [self findCard:card];
    if (index != -1)
    {
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
}

-(Deck*) copy
{
    Deck* newDeck = [Deck new];
    
    newDeck.identity = self.identity;
    newDeck->_cards = [NSMutableArray arrayWithArray:_cards];
    newDeck->_role = self.role;
    
    return newDeck;
}

-(int) findCard:(Card*) card
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
    
    if (self.identity)
    {
        CardCounter* identity = [CardCounter initWithCard:self.identity];
        [sections addObject:identity.card.typeStr];
        [cards addObject:@[ identity ]];
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
        _identity = [Card cardByCode:identityCode];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.cards forKey:@"cards"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInt:self.role forKey:@"role"];
    [coder encodeObject:self.identity.code forKey:@"identity"];
}


@end
