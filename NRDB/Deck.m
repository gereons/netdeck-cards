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
@property CardCounter* identityCc;
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
        self.dateCreated = [NSDate date];
    }
    return self;
}

-(Card*) identity
{
    return self.identityCc.card;
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
    [self addCard:card copies:copies history:YES];
}

// add (copies>0) or remove (copies<0) a copy of a card from the deck
// if copies==0, removes ALL copies of the card
-(void) addCard:(Card *)card copies:(int)copies history:(BOOL)history
{
    // NSLog(@"add %d copies of %@, hist=%d", copies, card.name, history);
    
    int cardIndex = [self indexOfCard:card];
    CardCounter* cc;
    
    if (card.type == NRCardTypeIdentity)
    {
        [self setIdentity:card copies:copies history:history];
        return;
    }

    if (cardIndex != -1)
    {
        cc = [_cards objectAtIndex:cardIndex];
    }

    if (copies < 1)
    {
        NSAssert(cc != nil, @"remove card that's not in the deck");
        // NSLog(@" remove %d copies of %@, index=%d", ABS(copies), card.name, cardIndex);
        // remove card
        if (copies == 0 || ABS(copies) >= cc.count)
        {
            [_cards removeObjectAtIndex:cardIndex];
            copies = -cc.count;
        }
        else
        {
            cc.count -= ABS(copies);
        }
    }
    else
    {
        // NSLog(@" add %d copies of %@, index=%d", ABS(copies), card.name, cardIndex);
        if (cc == nil)
        {
            cc = [CardCounter initWithCard:card andCount:copies];
            [_cards addObject:cc];
        }
        else
        {
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
    }
    
    if (history)
    {
        [self.lastChanges addCardCode:cc.card.code copies:copies];
    }
    
    [self sort];
}

-(void) setIdentity:(Card *)identity copies:(int)copies history:(BOOL)history
{
    if (self.identityCc && history)
    {
        // NSLog(@" remove old identity %@, hist=%d", self.identityCc.card.name, history);
        // record removal of existing identity
        [self.lastChanges addCardCode:self.identityCc.card.code copies:-1];
    }
    if (identity && copies > 0)
    {
        // NSLog(@" add new identity %@, hist=%d", identity.name, history);
        if (history)
        {
            [self.lastChanges addCardCode:identity.code copies:1];
        }
        
        self.identityCc = [CardCounter initWithCard:identity andCount:1];
        if (self.role != NRRoleNone)
        {
            NSAssert(self.role == identity.role, @"role mismatch");
        }
        self.role = identity.role;
    }
    else
    {
        // NSLog(@" deck has no identity");
        self.identityCc = nil;
    }
    self->_isDraft = [DRAFT_IDS containsObject:identity.code];
}

-(void) resetToCards:(NSDictionary *)cards
{
    NSMutableArray* newCards = [NSMutableArray array];

    Card* newIdentity;
    for (NSString* code in cards.allKeys)
    {
        Card* card = [Card cardByCode:code];
        
        if (card.type != NRCardTypeIdentity)
        {
            NSNumber* qty = cards[code];
            CardCounter* cc = [CardCounter initWithCard:card andCount:qty.intValue];
            [newCards addObject:cc];
        }
        else
        {
            NSAssert(newIdentity == nil, @"newIdentity already set");
            newIdentity = card;
        }
    }
    
    // figure out changes between this and the last saved state
    
    if (self.revisions.count > 0)
    {
        DeckChangeSet* dcs = self.revisions[0];
        NSDictionary* lastSavedCards = dcs.cards;
        NSArray* lastSavedCodes = lastSavedCards.allKeys;
        
        // for cards in last saved deck, check what remains in new deck
        for (NSString* code in lastSavedCodes)
        {
            NSNumber* oldQty = lastSavedCards[code];
            NSNumber* newQty = cards[code];
            if (newQty == nil)
            {
                // not in new deck
                [self.lastChanges addCardCode:code copies:-oldQty.intValue];
            }
            else
            {
                int diff = oldQty.intValue - newQty.intValue;
                if (diff != 0)
                {
                    [self.lastChanges addCardCode:code copies:diff];
                }
            }
        }
        
        // for cards in new deck: check what was in old deck
        for (NSString* code in cards.allKeys)
        {
            if (![lastSavedCodes containsObject:code])
            {
                NSNumber* newQty = cards[code];
                [self.lastChanges addCardCode:code copies:newQty.intValue];
            }
        }
    }
    
    [self setIdentity:newIdentity copies:1 history:NO];
    
    self->_cards = newCards;
}

-(Deck*) duplicate
{
    Deck* newDeck = [[Deck alloc] init];
    
    newDeck.name = [NSString stringWithFormat:l10n(@"Copy of %@"), self.name];
    newDeck->_identityCc = [CardCounter initWithCard:self.identity];
    newDeck->_isDraft = self.isDraft;
    newDeck->_cards = [NSMutableArray arrayWithArray:_cards];
    newDeck->_role = self.role;
    newDeck.filename = nil;
    newDeck.state = self.state;
    newDeck.notes = self.notes ? [NSString stringWithString:self.notes] : nil;
    
    newDeck.lastChanges = self.lastChanges;
    newDeck->_revisions = [NSMutableArray arrayWithArray:self.revisions];
    
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

-(void) clearChanges
{
    self.lastChanges = [[DeckChangeSet alloc] init];
}

-(void) mergeRevisions
{
    [self.lastChanges coalesce];
    
    if (self.lastChanges.changes.count > 0)
    {
        self.lastChanges.cards = [NSMutableDictionary dictionary];
        for (CardCounter* cc in self.allCards)
        {
            self.lastChanges.cards[cc.card.code] = @(cc.count);
        }
        
        if (self.revisions.count == 0)
        {
            // this is the first revision
            self.lastChanges.initial = YES;
        }
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
        [self addCard:card copies:0 history:NO];
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
