//
//  DeckChange.m
//  NRDB
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckChange.h"
#import "card.h"

@implementation DeckChange

-(Card*) card
{
    return [Card cardByCode:self.code];
}

#pragma mark NSCoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.count = [decoder decodeIntegerForKey:@"count"];
        self.code = [decoder decodeObjectForKey:@"code"];
        self.op = [decoder decodeIntegerForKey:@"op"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.code forKey:@"code"];
    [coder encodeInteger:self.op forKey:@"op"];
    [coder encodeInteger:self.count forKey:@"count"];
}



@end
