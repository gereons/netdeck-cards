//
//  CardList.m
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardList.h"
#import "Card.h"
#import "Deck.h"
#import "CardSets.h"
#import "CardManager.h"

@interface CardList()

@property NRRole role;
@property NSMutableArray* initialCards;

@property int cost;
@property NSString* type;
@property NSSet* types;
@property NSString* subtype;
@property NSSet* subtypes;
@property int strength;
@property int mu;
@property int trash;
@property NSString* faction;
@property NSSet* factions;
@property int influence;
@property NSString* set;
@property NSSet* sets;
@property int agendaPoints;
@property NSString* text;
@property NRSearchScope searchScope;
@property BOOL unique;
@property BOOL limited;
@property BOOL altart;
@property NRFaction faction4inf;    // faction for influence filter

@property NRCardListSortType sortType;

@end

@implementation CardList

-(CardList*) initForRole:(NRRole)role
{
    if ((self = [super init]))
    {
        self.role = role;
        self.sortType = NRCardListSortA_Z;
        self.faction4inf = NRFactionNone;
        [self resetInitialCards];
        [self clearFilters];
    }
    return self;
}

+(CardList*) browserInitForRole:(NRRole)role
{
    CardList* cl = [[CardList alloc] init];
    cl.sortType = NRCardListSortA_Z;
    cl.role = role;
    
    NSArray* roles;
    switch (role)
    {
        case NRRoleNone:
            roles = @[ @(NRRoleRunner), @(NRRoleCorp) ];
            break;
        case NRRoleCorp:
            roles = @[ @(NRRoleCorp) ];
            break;
        case NRRoleRunner:
            roles = @[ @(NRRoleRunner) ];
            break;
    }
    
    cl.initialCards = [NSMutableArray array];
    
    for (NSNumber* r in roles)
    {
        [cl.initialCards addObjectsFromArray:[CardManager allForRole:r.intValue]];
        [cl.initialCards addObjectsFromArray:[CardManager identitiesForRole:r.intValue]];
    }
    [cl filterDeselectedSets];
    [cl clearFilters];
    
    return cl;
}

-(void) resetInitialCards
{
    self.initialCards = [NSMutableArray arrayWithArray:[CardManager allForRole:self.role]];
    [self filterDeselectedSets];
}

-(void) filterDeselectedSets
{
    // remove all cards from sets that are deselected
    NSSet* disabledSetCodes = [CardSets disabledSetCodes];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"!(setCode in %@)", disabledSetCodes];
    [self.initialCards filterUsingPredicate:predicate];
}

-(void) filterAgendas:(Card *)identity
{
    [self resetInitialCards];
    
    if (identity && identity.faction != NRFactionNeutral)
    {
        NSArray* factions = @[ @(NRFactionNeutral), @(identity.faction) ];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"type != %d OR (type = %d AND faction in %@)", NRCardTypeAgenda, NRCardTypeAgenda, factions];
        
        [self.initialCards filterUsingPredicate:predicate];
    }
    
    [self applyFilters];
}

-(void) clearFilters
{
    self.cost = -1;
    self.type = @"";
    self.types = nil;
    self.subtype = @"";
    self.subtypes = nil;
    self.strength = -1;
    self.mu = -1;
    self.trash = -1;
    self.faction = @"";
    self.factions = nil;
    self.influence = -1;
    self.set = @"";
    self.sets = nil;
    self.agendaPoints = -1;
    self.text = @"";
    self.searchScope = NRSearchAll;
    self.unique = NO;
    self.limited = NO;
    self.altart = NO;
    self.faction4inf = NRFactionNone;
}

-(void) filterByType:(NSString*) type
{
    self.type = type;
    self.types = nil;
}

-(void) filterByTypes:(NSSet *)types
{
    self.type = @"";
    self.types = types;
}

-(void) filterByFaction:(NSString*) faction
{
    self.faction = faction;
    self.factions = nil;
}

-(void) filterByFactions:(NSSet*) factions
{
    self.faction = @"";
    self.factions = factions;
}

-(void) filterByText:(NSString*) text;
{
    self.text = text;
    self.searchScope = NRSearchText;
}

-(void) filterByTextOrName:(NSString*) text;
{
    self.text = text;
    self.searchScope = NRSearchAll;
}

-(void) filterByName:(NSString*) name;
{
    self.text = name;
    self.searchScope = NRSearchName;
}

-(void) filterBySet:(NSString*) set;
{
    self.set = set;
    self.sets = nil;
}

-(void) filterBySets:(NSSet*) sets;
{
    self.set = @"";
    self.sets = sets;
}

-(void) filterByInfluence:(int)influence
{
    self.influence = influence;
    self.faction4inf = NRFactionNone;
}

-(void) filterByInfluence:(int)influence forFaction:(NRFaction)faction
{
    self.influence = influence;
    self.faction4inf = faction;
}

-(void) filterByMU:(int)mu
{
    self.mu = mu;
}

-(void) filterByTrash:(int)trash
{
    self.trash = trash;
}

-(void) filterByCost:(int)cost
{
    self.cost = cost;
}

-(void) filterBySubtype:(NSString *)subtype
{
    self.subtype = subtype;
    self.subtypes = nil;
}

-(void) filterBySubtypes:(NSSet *)subtypes
{
    self.subtype = @"";
    self.subtypes = subtypes;
}

-(void) filterByStrength:(int)strength
{
    self.strength = strength;
}

-(void) filterByAgendaPoints:(int)ap
{
    self.agendaPoints = ap;
}

-(void) filterByUniqueness:(BOOL)unique
{
    self.unique = unique;
}

-(void) filterByLimited:(BOOL)limited
{
    self.limited = limited;
}

-(void) filterByAltArt:(BOOL)altart
{
    self.altart = altart;
}

-(void) sortBy:(NRCardListSortType)sortType
{
    self.sortType = sortType;
}

-(NSMutableArray*) applyFilters
{
    NSMutableArray* filteredCards = [self.initialCards mutableCopy];
    NSMutableArray* predicates = [NSMutableArray array];
    
    if (self.faction.length > 0 && ![self.faction isEqualToString:kANY])
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"factionStr LIKE[cd] %@", self.faction];
        [predicates addObject:predicate];
    }
    if (self.factions.count > 0)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"factionStr IN %@", self.factions];
        [predicates addObject:predicate];
    }
    if (self.type.length > 0 && ![self.type isEqualToString:kANY])
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"typeStr LIKE[cd] %@", self.type];
        [predicates addObject:predicate];
    }
    if (self.types.count > 0)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"typeStr IN %@", self.types];
        [predicates addObject:predicate];
    }
    if (self.mu != -1)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"mu == %d", self.mu];
        [predicates addObject:predicate];
    }
    if (self.trash != -1)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"trash == %d", self.trash];
        [predicates addObject:predicate];
    }
    if (self.strength != -1)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"strength == %d", self.strength];
        [predicates addObject:predicate];
    }
    if (self.influence != -1)
    {
        if (self.faction4inf == NRFactionNone)
        {
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"influence == %d", self.influence];
            [predicates addObject:predicate];
        }
        else
        {
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"influence == %d && faction != %d", self.influence, self.faction4inf];
            [predicates addObject:predicate];
        }
    }
    if (self.set.length > 0 && ![self.set isEqualToString:kANY])
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"setName LIKE[cd] %@", self.set];
        [predicates addObject:predicate];
    }
    if (self.sets.count > 0)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"setName IN %@", self.sets];
        [predicates addObject:predicate];
    }
    if (self.cost != -1)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"cost == %d || advancementCost == %d", self.cost, self.cost];
        [predicates addObject:predicate];
    }
    if (self.subtype.length > 0 && ![self.subtype isEqualToString:kANY])
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%@ IN subtypes", self.subtype];
        [predicates addObject:predicate];
    }
    if (self.subtypes.count > 0)
    {
        NSMutableArray *subPredicates = [NSMutableArray array];
        for (NSString* subtype in self.subtypes)
        {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"%@ IN subtypes", subtype]];
        }
        NSPredicate *subtypePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:subPredicates];
        [predicates addObject:subtypePredicate];
    }
    if (self.agendaPoints != -1)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"agendaPoints == %d", self.agendaPoints];
        [predicates addObject:predicate];
    }
    if (self.text.length > 0)
    {
        NSPredicate* predicate;
        switch (self.searchScope)
        {
            case NRSearchAll:
                predicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) OR (text CONTAINS[cd] %@)", self.text, self.text];
                break;
            case NRSearchName:
            {
                predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", self.text];
                unichar ch = [self.text characterAtIndex:0];
                if (isdigit(ch))
                {
                    NSPredicate* codePredicate = [NSPredicate predicateWithFormat:@"code BEGINSWITH %@", self.text ];
                    predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[ predicate, codePredicate ]];
                }
                break;
            }
            case NRSearchText:
                predicate = [NSPredicate predicateWithFormat:@"text CONTAINS[cd] %@", self.text];
                break;
        }
        [predicates addObject:predicate];
    }
    if (self.unique)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"unique == 1"];
        [predicates addObject:predicate];
    }
    if (self.limited)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"maxPerDeck == 1"];
        [predicates addObject:predicate];
    }
    if (self.altart)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"altCard != NIL"];
        [predicates addObject:predicate];
    }

    if (predicates.count > 0)
    {
        NSPredicate* allPredicates = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
        [filteredCards filterUsingPredicate:allPredicates];
    }
    
    return filteredCards;
}

-(void) sort:(NSMutableArray*)cards
{
    [cards sortUsingComparator:^NSComparisonResult(Card* c1, Card* c2) {
        if (c1.type > c2.type)
        {
            return NSOrderedDescending;
        }
        else if (c1.type < c2.type)
        {
            return NSOrderedAscending;
        }
        
        NSComparisonResult cmp = NSOrderedSame;
        if (self.sortType == NRCardListSortFactionA_Z)
        {
            cmp = [c1.factionStr compare:c2.factionStr];
        }
        if (cmp == NSOrderedSame)
        {
            return [c1.name localizedCaseInsensitiveCompare:c2.name];
        }
        return cmp;
    }];
}

-(NSUInteger) count
{
    NSArray* arr = [self applyFilters];
    return arr.count;
}

-(TableData*) dataForTableView
{
    NSMutableArray* sections = [NSMutableArray array];
    NSMutableArray* cards = [NSMutableArray array];
    
    NSMutableArray* filteredCards = [self applyFilters];
    [self sort:filteredCards];
    NRCardType prevType = NRCardTypeNone;
    NSMutableArray* arr;
    for (Card* card in filteredCards)
    {
        if (card.type != prevType)
        {
            [sections addObject:card.typeStr];
            if (arr != nil)
            {
                [cards addObject:arr];
            }
            arr = [NSMutableArray array];
        }
        [arr addObject:card];
        prevType = card.type;
    }
    
    if (arr.count > 0)
    {
        [cards addObject:arr];
    }
    
    NSAssert(sections.count == cards.count, @"count mismatch");
    
    return [[TableData alloc] initWithSections:sections andValues:cards];
}

@end
