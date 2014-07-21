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
#if DEBUG
@property NSString* idCode;
#endif

@end

static NSArray* draftIds;

@implementation Deck

+(void) initialize
{
    draftIds = @[ THE_MASQUE, THE_SHADOW ];
}

-(Deck*) init
{
    if ((self = [super init]))
    {
        self->_cards = [NSMutableArray array];
        self.state = NRDeckStateTesting;
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
        self->_identityCc = [CardCounter initWithCard:identity andCount:1];
        self.role = identity.role;
#if DEBUG
        self.idCode = identity.code;
#endif
    }
    else
    {
        self->_identityCc = nil;
#if DEBUG
        self.idCode = nil;
#endif
    }
    
    self->_isDraft = [draftIds containsObject:identity.code];
}

-(NSArray*) cards
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
    return self->_cards;
}

-(NSArray*) allCards
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
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
    
    if (!self.isDraft && self.influence > self.identity.influenceLimit)
    {
        [reasons addObject:l10n(@"Too much influence used")];
    }
    
    if (self.size < self.identity.minimumDecksize)
    {
        [reasons addObject:l10n(@"Not enough cards")];
    }
    
    NRRole role = self.identity.role;
    if (role == NRRoleCorp)
    {
        // check agenda points
        int apRequired = ((self.size / 5) + 1) * 2;
        if (self.agendaPoints != apRequired && self.agendaPoints != apRequired+1)
        {
            [reasons addObject:[NSString stringWithFormat:l10n(@"AP must be %d or %d"), apRequired, apRequired+1]];
        }
    }
    
    BOOL noJintekiAllowed = [self.identity.code isEqualToString:CUSTOM_BIOTICS];
    
    BOOL petError = NO, jintekiError = NO, agendaError = NO, entError = NO;
    BOOL hfError = NO, hsError = NO, usError = NO, efError = NO, esError = NO, ufError = NO;
    
    // check max 1 per deck restrictions
    for (CardCounter* cc in self.cards)
    {
        Card* card = cc.card;
        
        if (role == NRRoleCorp)
        {
            if ([card.code isEqualToString:DIRECTOR_HAAS_PET_PROJ] && cc.count > 1 && !petError)
            {
                petError = YES;
                [reasons addObject:l10n(@"Too many pet projects")];
            }
            
            if ([card.code isEqualToString:PHILOTIC_ENTANGLEMENT] && cc.count > 1 && !entError)
            {
                entError = YES;
                [reasons addObject:l10n(@"Too many entanglements")];
            }
            
            if ([card.code isEqualToString:HADES_FRAGMENT] && cc.count > 1 && !hfError)
            {
                hfError = YES;
                [reasons addObject:l10n(@"Too many Hades Fragments")];
            }
            
            if ([card.code isEqualToString:EDEN_FRAGMENT] && cc.count > 1 && !efError)
            {
                efError = YES;
                [reasons addObject:l10n(@"Too many Eden Fragments")];
            }
            
            if ([card.code isEqualToString:UTOPIA_FRAGMENT] && cc.count > 1 && !ufError)
            {
                ufError = YES;
                [reasons addObject:l10n(@"Too many Utopia Fragments")];
            }
            
            if (noJintekiAllowed && card.faction == NRFactionJinteki && !jintekiError)
            {
                jintekiError = YES;
                [reasons addObject:l10n(@"Cannot include Jinteki")];
            }
            
            if (!self.isDraft && card.type == NRCardTypeAgenda && card.faction != NRFactionNeutral && card.faction != self.identity.faction && !agendaError)
            {
                agendaError = YES;
                [reasons addObject:l10n(@"Cannot use out-of-faction agendas")];
            }
        }
        else
        {
            // runner-only checks
            if ([card.code isEqualToString:HADES_SHARD] && cc.count > 1 && !hsError)
            {
                hsError = YES;
                [reasons addObject:l10n(@"Too many Hades Shards")];
            }
            if ([card.code isEqualToString:EDEN_SHARD] && cc.count > 1 && !esError)
            {
                esError = YES;
                [reasons addObject:l10n(@"Too many Eden Shards")];
            }
            if ([card.code isEqualToString:UTOPIA_SHARD] && cc.count > 1 && !usError)
            {
                usError = YES;
                [reasons addObject:l10n(@"Too many Utopia Shards")];
            }
        }
    }
    
    return reasons;
}


-(int) size
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
    int sz = 0;
    for (CardCounter* cc in _cards)
    {
        sz += cc.count;
    }
    return sz;
}

-(int) agendaPoints
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
    int ap = 0;
    
    for (CardCounter* cc in _cards)
    {
        if (cc.card.type == NRCardTypeAgenda)
        {
            ap += cc.card.agendaPoints * cc.count;
        }
    }
    return ap;
}

-(int) influence
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
    int inf = 0;
    BOOL isProfessor = [self.identity.code isEqualToString:THE_PROFESSOR];
    
    for (CardCounter* cc in _cards)
    {
        if (cc.card.faction != self.identity.faction && cc.card.influence != -1)
        {
            NSUInteger count = cc.count;
            
            if (isProfessor && cc.card.type == NRCardTypeProgram)
            {
                --count;
            }
            
            inf += cc.card.influence * count;
        }
    }
    return inf;
}

-(NSUInteger) influenceFor:(CardCounter *)cc
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
    if (self.identity.faction == cc.card.faction || cc.card.influence == -1)
    {
        return 0;
    }
    
    NSUInteger count = cc.count;
    if (cc.card.type == NRCardTypeProgram && [self.identity.code isEqualToString:THE_PROFESSOR])
    {
        --count;
    }
    
    return count * cc.card.influence;
}

-(void) addCard:(Card *)card copies:(int)copies
{
    NSAssert(card.type != NRCardTypeIdentity, @"can't add identity");
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
    int index = [self indexOfCard:card];
    if (index == -1)
    {
        CardCounter* cc = [CardCounter initWithCard:card andCount:copies];
        [_cards addObject:cc];
    }
    else
    {
        CardCounter* cc = [_cards objectAtIndex:index];
        if (self.isDraft)
        {
            cc.count += copies;
        }
        else
        {
            int max = cc.card.maxCopies;
            if (cc.count < max)
            {
                cc.count = MIN(max, cc.count + copies);
            }
        }
    }
    [self sort];
}

-(void) removeCard:(Card *)card
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
    [self removeCard:card copies:-1];
}

-(void) removeCard:(Card *)card copies:(int)copies
{
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
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
    newDeck->_identityCc = [CardCounter initWithCard:self.identity];
    newDeck->_isDraft = self.isDraft;
    newDeck->_cards = [NSMutableArray arrayWithArray:_cards];
    newDeck->_role = self.role;
    newDeck.filename = nil;
    newDeck.state = self.state;
    newDeck.notes = self.notes ? [NSString stringWithString:self.notes] : nil;
    
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
#if DEBUG
    if (self.idCode)
    {
        NSAssert([self.idCode isEqualToString:self.identity.code], @"code mismatch");
    }
#endif
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
        _netrunnerDbId = [decoder decodeObjectForKey:@"netrunnerDbId"];
        _name = [decoder decodeObjectForKey:@"name"];
        _role = [decoder decodeIntForKey:@"role"];
        _state = [decoder decodeIntForKey:@"state"];
        _isDraft = [decoder decodeBoolForKey:@"draft"];
        NSString* identityCode = [decoder decodeObjectForKey:@"identity"];
        Card* identity = [Card cardByCode:identityCode];
        if (identity)
        {
            _identityCc = [CardCounter initWithCard:identity andCount:1];
        }
#if DEBUG
        self.idCode = identity.code;
#endif
        _identityCc.showAltArt = [decoder decodeBoolForKey:@"identityAltArt"];
        _lastModified = nil;
        _notes = [decoder decodeObjectForKey:@"notes"];
        _tags = [decoder decodeObjectForKey:@"tags"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.cards forKey:@"cards"];
    [coder encodeObject:self.netrunnerDbId forKey:@"netrunnerDbId"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInt:self.role forKey:@"role"];
    [coder encodeInt:self.state forKey:@"state"];
    [coder encodeBool:self.isDraft forKey:@"draft"];
    [coder encodeObject:self.identity.code forKey:@"identity"];
    [coder encodeBool:self.identityCc.showAltArt forKey:@"identityAltArt"];
    [coder encodeObject:self.notes forKey:@"notes"];
    [coder encodeObject:self.tags forKey:@"tags"];
}


@end
