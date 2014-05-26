//
//  CardList.m
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardList.h"
#import "Card.h"
#import "CardSets.h"
#import "CardData.h"

@interface CardList()

@property NSMutableArray* initialCards;

@property int cost;
@property NSString* type;
@property NSSet* types;
@property NSString* subtype;
@property NSSet* subtypes;
@property int strength;
@property int mu;
@property NSString* faction;
@property NSSet* factions;
@property int influence;
@property NSString* set;
@property NSSet* sets;
@property int agendaPoints;
@property NSString* text;
@property NRSearchScope searchScope;
@end

@implementation CardList

-(CardList*) initForRole:(NRRole)role
{
    if ((self = [super init]))
    {
        self.initialCards = [NSMutableArray arrayWithArray:[Card allForRole:role]];
        
        // remove all cards from sets that are deselected
        NSSet* removeSets = [CardSets disabledSetCodes];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"!(setCode in %@)", removeSets];
        [self.initialCards filterUsingPredicate:predicate];
        
        [self clearFilters];
    }
    return self;
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
    self.faction = @"";
    self.factions = nil;
    self.influence = -1;
    self.set = @"";
    self.sets = nil;
    self.agendaPoints = -1;
    self.text = @"";
    self.searchScope = NRSearchAll;
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
}

-(void) filterByMU:(int)mu
{
    self.mu = mu;
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
    if (self.strength != -1)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"strength == %d", self.strength];
        [predicates addObject:predicate];
    }
    if (self.influence != -1)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"influence == %d", self.influence];
        [predicates addObject:predicate];
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
                predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", self.text];
                break;
            case NRSearchText:
                predicate = [NSPredicate predicateWithFormat:@"text CONTAINS[cd] %@", self.text];
                break;
        }
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
        else
        {
            return [c1.name localizedCaseInsensitiveCompare:c2.name];
        }
    }];
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
