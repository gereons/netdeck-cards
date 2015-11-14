//
//  DeckChange.m
//  Net Deck
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "DeckChange.h"
#import "Card.h"

@implementation xDeckChange

+(xDeckChange*) forCode:(NSString*)code copies:(NSInteger)copies
{
    NSAssert(copies != 0, @"copies can't be 0");
    xDeckChange* dc = [[xDeckChange alloc] init];
    dc->_code = code;
    dc->_count = copies;
    return dc;
}

-(Card*) card
{
    return [Card cardByCode:self.code];
}

#pragma mark NSCoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self->_count = [decoder decodeIntegerForKey:@"count"];
        self->_code = [decoder decodeObjectForKey:@"code"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.code forKey:@"code"];
    [coder encodeInteger:self.count forKey:@"count"];
}



@end
