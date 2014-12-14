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
    NSAssert(copies != 0, @"changing 0 copies?");
    DeckChange* dc = [DeckChange forCode:card.code copies:copies];
    
    [self.changes addObject:dc];
}

-(void) dump
{
    NSLog(@"---- changes -----");
    for (DeckChange* dc in self.changes)
    {
        NSLog(@"%@ %d %@", dc.count > 0 ? @"add" : @"rem",
              dc.count,
              dc.card.name);
    }
    NSLog(@"---end---");
}

-(void) coalesce
{
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
    self.timestamp = [NSDate date];
    
    // [self dump];
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
