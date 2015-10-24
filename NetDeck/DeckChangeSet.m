//
//  DeckChangeSet.m
//  Net Deck
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
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
        self.initial = NO;
        self.cards = nil;
    }
    return self;
}

-(void) addCardCode:(NSString *)code copies:(NSInteger)copies
{
    NSAssert(copies != 0, @"changing 0 copies?");
    DeckChange* dc = [DeckChange forCode:code copies:copies];
    
    [self.changes addObject:dc];
}

-(void) dump
{
    NSLog(@"---- changes -----");
    for (DeckChange* dc in self.changes)
    {
        NSLog(@"%@ %ld %@", dc.count > 0 ? @"add" : @"rem",
              (long)dc.count,
              dc.card.name);
    }
    NSLog(@"---end---");
}

-(void) coalesce
{
    if (self.changes.count == 0)
    {
        return;
    }
    
    // sort by card
    NSArray* arr = [self.changes sortedArrayUsingComparator:^NSComparisonResult(DeckChange* dc1, DeckChange* dc2) {
        return [dc1.code compare:dc2.code];
    }];
    
    NSMutableArray* combinedChanges = [NSMutableArray array];
    NSString* prevCode = nil;
    NSInteger count = 0;
    for (DeckChange* dc in arr)
    {
        if (prevCode && ![dc.code isEqualToString:prevCode])
        {
            if (count != 0)
            {
                DeckChange* newDc = [DeckChange forCode:prevCode copies:count];
                
                [combinedChanges addObject:newDc];
            }
            
            count = 0;
        }
        
        prevCode = dc.code;
        count += dc.count;
    }
    if (prevCode && count != 0)
    {
        DeckChange* newDc = [DeckChange forCode:prevCode copies:count];
        [combinedChanges addObject:newDc];
    }
    
    self.changes = combinedChanges;
    [self sort];
    self.timestamp = [NSDate date];
    
    // [self dump];
}

// sort changes: additions by name, then deletions by name
-(void) sort
{
    [self.changes sortUsingComparator:^NSComparisonResult(DeckChange* dc1, DeckChange* dc2) {
        // NSComparisonResult rs = NSOrderedSame;
    
        if (dc1.count > 0 && dc2.count < 0)
        {
            return NSOrderedAscending;
        }
        if (dc1.count < 0 && dc2.count > 0)
        {
            return NSOrderedDescending;
        }
        return [dc1.card.name compare:dc2.card.name];
    }];
}

#pragma mark nscoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.timestamp = [decoder decodeObjectForKey:@"timestamp"];
        self.changes = [decoder decodeObjectForKey:@"changes"];
        self.initial = [decoder decodeBoolForKey:@"initial"];
        self.cards = [decoder decodeObjectForKey:@"cards"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.timestamp forKey:@"timestamp"];
    [coder encodeObject:self.changes forKey:@"changes"];
    [coder encodeBool:self.initial forKey:@"initial"];
    [coder encodeObject:self.cards forKey:@"cards"];
}

@end
