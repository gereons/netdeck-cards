//
//  CardCounter.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CardCounter.h"
#import "Card.h"

@implementation CardCounter

+(CardCounter*) initWithCard:(Card*)card
{
    return [self initWithCard:card andCount:1];
}

+(CardCounter*) initWithCard:(Card*)card andCount:(int)count
{
    CardCounter* cc = [CardCounter new];
    cc->_card = card;
    cc.count = count;
    
    return cc;
}

-(void) setCount:(int)count
{
    NSAssert(count >= 0 && count < 4, @"wrong card count");
    self->_count = count;
}

#pragma mark NSCoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.count = [decoder decodeIntForKey:@"count"];
        NSString* code = [decoder decodeObjectForKey:@"card"];
        _card = [Card cardByCode:code];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:self.count forKey:@"count"];
    [coder encodeObject:self.card.code forKey:@"card"];
}

@end
