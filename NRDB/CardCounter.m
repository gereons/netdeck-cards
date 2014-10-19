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

@synthesize card = _card;

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

#pragma mark NSCoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.showAltArt = [decoder decodeBoolForKey:@"altArt"];
        NSString* code = [decoder decodeObjectForKey:@"card"];
        _card = [Card cardByCode:code];
        self.count = [decoder decodeIntegerForKey:@"count"];
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
