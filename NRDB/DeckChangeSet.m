//
//  DeckChangeSet.m
//  NRDB
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckChangeSet.h"
#import "DeckChange.h"
#import "Card.h"

@implementation DeckChangeSet

-(id) init
{
    if ((self = [super init]))
    {
        self.changes = [NSMutableArray array];
    }
    return self;
}

-(void) addCard:(Card *)card copies:(int)copies
{
    DeckChange* dc = [[DeckChange alloc] init];
    dc.count = copies;
    dc.code = card.code;
    dc.op = NRDeckChangeAddCard;
    
    [self.changes addObject:dc];
    [self dump];
}

-(void) removeCard:(Card *)card copies:(int)copies
{
    DeckChange* dc = [[DeckChange alloc] init];
    dc.count = copies;
    dc.code = card.code;
    dc.op = NRDeckChangeRemoveCard;
    
    [self.changes addObject:dc];
    [self dump];
}

-(void) dump
{
    NSLog(@"---- changes -----");
    for (DeckChange* dc in self.changes)
    {
        NSLog(@"%@ %d %@", dc.op == NRDeckChangeAddCard ? @"add" : @"rem",
              dc.count,
              dc.card.name);
    }
    NSLog(@"---end---");
}

-(void) coalesce
{
}

#pragma mark nscoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.timestamp = [decoder decodeObjectForKey:@"timestamp"];
        self.changes = [decoder decodeObjectForKey:@"changes"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.timestamp forKey:@"timestamp"];
    [coder encodeObject:self.changes forKey:@"changes"];
}


@end
