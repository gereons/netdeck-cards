//
//  CardCounter.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
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
    NSAssert(card != nil, @"card is nil");
    CardCounter* cc = [CardCounter new];
    cc->_card = card;
    cc.count = count;
    cc.showAltArt = NO;
    
    return cc;
}

-(void) setCount:(NSUInteger)count
{
    self->_count = count;
}

#pragma mark NSCoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.count = [decoder decodeIntegerForKey:@"count"];
        self.showAltArt = [decoder decodeBoolForKey:@"altArt"];
        NSString* code = [decoder decodeObjectForKey:@"card"];
        _card = [Card cardByCode:code];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:self.count forKey:@"count"];
    [coder encodeObject:self.card.code forKey:@"card"];
    [coder encodeBool:self.showAltArt forKey:@"altArt"];
}

@end
