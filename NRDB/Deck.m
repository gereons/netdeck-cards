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
#import "DeckChange.h"
#import "DeckChangeSet.h"

@interface Deck()
{
    NSMutableArray* _cards;     // array of CardCounter
    NSMutableArray* _revisions; // array of DeckChangeSet
}
@property NRDeckSort sortType;
@property DeckChangeSet* lastChanges;

@end

@implementation Deck

-(Deck*) init
{
    if ((self = [super init]))
    {
        self->_cards = [NSMutableArray array];
        self->_revisions = [NSMutableArray array];
        self.state = NRDeckStateTesting;
        self.role = NRRoleNone;
        self.sortType = NRDeckSortType;
        self.lastChanges = [[DeckChangeSet alloc] init];
    }
    return self;
}

-(Card*) identity
{
    return self.identityCc.card;
}

-(void) setIdentity:(Card *)identity
{
    if (self->_identityCc)
    {
        [self.lastChanges removeCard:self->_identityCc.card copies:1];
    }
    if (identity)
    {
        [self.lastChanges addCard:identity copies:1];
        
        self->_identityCc = [CardCounter initWithCard:identity andCount:1];
        if (self.role != NRRoleNone)
        {
            NSAssert(self.role == identity.role, @"role mismatch");
        }
        self.role = identity.role;
    }
    else
    {
        self->_identityCc = nil;
    }
    self->_isDraft = [DRAFT_IDS containsObject:identity.code];
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
    BOOL fragError = NO, shardError = NO;
    
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
            
            BOOL isFragment = [card.code isEqualToString:HADES_FRAGMENT] || [card.code isEqualToString:EDEN_FRAGMENT] || [card.code isEqualToString:UTOPIA_FRAGMENT];
            if (isFragment && cc.count > 1 && !fragError)
            {
                fragError = YES;
                [reasons addObject:l10n(@"Too many fragments")];
            }
            
            if (noJintekiAllowed && card.faction == NRFactionJinteki && !jintekiError)
            {
                jintekiError = YES;
                [reasons addObject:l10n(@"Faction no allowed")];
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
            BOOL isShard = [card.code isEqualToString:HADES_SHARD] || [card.code isEqualToString:EDEN_SHARD] || [card.code isEqualToString:UTOPIA_SHARD];
            if (isShard && cc.count > 1 && !shardError)
            {
                shardError = YES;
                [reasons addObject:l10n(@"Too many shards")];
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

    int index = [self indexOfCard:card];
    CardCounter* cc;
    if (index == -1)
    {
        cc = [CardCounter initWithCard:card andCount:copies];
        [_cards addObject:cc];
    }
    else
    {
        cc = [_cards objectAtIndex:index];
        if (self.isDraft)
        {
            cc.count += copies;
        }
        else
        {
            int max = cc.card.maxPerDeck;
            if (cc.count < max)
            {
                cc.count = MIN(max, cc.count + copies);
            }
        }
    }
    
    [self.lastChanges addCard:cc.card copies:copies];
    
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
    
    CardCounter* cc = [_cards objectAtIndex:index];
    if (copies == -1 || copies >= cc.count)
    {
        [_cards removeObjectAtIndex:index];
        copies = cc.count;
    }
    else
    {
        cc.count -= copies;
    }
    
    [self.lastChanges removeCard:cc.card copies:copies];
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
        if (self.sortType == NRDeckSortSetType || self.sortType == NRDeckSortSetNum)
        {
            if (c1.card.setNumber > c2.card.setNumber) return NSOrderedDescending;
            if (c1.card.setNumber < c2.card.setNumber) return NSOrderedAscending;
        }
        if (self.sortType == NRDeckSortFactionType)
        {
            if (c1.card.faction > c2.card.faction) return NSOrderedDescending;
            if (c1.card.faction < c2.card.faction) return NSOrderedAscending;
        }
        
        if (self.sortType == NRDeckSortSetNum)
        {
            return [@(c1.card.number) compare:@(c2.card.number)];
        }
        
        if (c1.card.type > c2.card.type) return NSOrderedDescending;
        if (c1.card.type < c2.card.type) return NSOrderedAscending;
        
        NSComparisonResult cmp = NSOrderedSame;
        if (c1.card.type == NRCardTypeIce && c2.card.type == NRCardTypeIce)
        {
            cmp = [c1.card.iceType compare:c2.card.iceType];
        }
        if (c1.card.type == NRCardTypeProgram && c2.card.type == NRCardTypeProgram)
        {
            cmp = [c1.card.programType compare:c2.card.programType];
        }
        if (cmp == NSOrderedSame)
        {
            cmp = [c1.card.name localizedCaseInsensitiveCompare:c2.card.name];
        }
        return cmp;
    }];
}

#pragma mark revisions

-(void) mergeRevisions
{
    if (self.lastChanges.changes.count > 0)
    {
        [self.lastChanges coalesce];
        [self->_revisions insertObject:self.lastChanges atIndex:0];
        self.lastChanges = [[DeckChangeSet alloc] init];
    }
}

#pragma mark table view data

-(TableData*) dataForTableView:(NRDeckSort)sortType
{
    self.sortType = sortType;
    
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
        NSAssert(cc.count > 0, @"found card with 0 copies?");
        if (cc.count == 0)
        {
            [removals addObject:cc.card];
        }
    }
    for (Card* card in removals)
    {
        [self removeCard:card];
    }
    
    NSString* prevSection = @"";
    NSMutableArray* arr;
    
    for (CardCounter* cc in self.cards)
    {
        NSString* section;
        
        switch (self.sortType)
        {
            case NRDeckSortType:
                section = cc.card.typeStr;
                if (cc.card.type == NRCardTypeIce)
                {
                    section = cc.card.iceType;
                }
                if (cc.card.type == NRCardTypeProgram)
                {
                    section = cc.card.programType;
                }
                break;
            case NRDeckSortSetType:
            case NRDeckSortSetNum:
                section = cc.card.setName;
                break;
            case NRDeckSortFactionType:
                section = cc.card.factionStr;
                break;
        }
        
        if (![section isEqualToString:prevSection])
        {
            [sections addObject:section];
            if (arr != nil)
            {
                [cards addObject:arr];
            }
            arr = [NSMutableArray array];
        }
        [arr addObject:cc];
        prevSection = section;
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
        // remove any cards we couldn't deserialize
        for (long i = _cards.count-1; i>=0; --i)
        {
            CardCounter* cc = _cards[i];
            if (cc.card == nil)
            {
                [_cards removeObjectAtIndex:i];
            }
        }
        
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
        _identityCc.showAltArt = [decoder decodeBoolForKey:@"identityAltArt"];
        _lastModified = nil;
        _notes = [decoder decodeObjectForKey:@"notes"];
        _tags = [decoder decodeObjectForKey:@"tags"];
        _sortType = NRDeckSortType;
        
        _lastChanges = [decoder decodeObjectForKey:@"lastChanges"];
        if (!_lastChanges)
        {
            _lastChanges = [[DeckChangeSet alloc] init];
        }
        _revisions = [decoder decodeObjectForKey:@"revisions"];
        if (!_revisions)
        {
            _revisions = [NSMutableArray array];
        }
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
    [coder encodeObject:self.lastChanges forKey:@"lastChanges"];
    [coder encodeObject:self.revisions forKey:@"revisions"];
}


@end
