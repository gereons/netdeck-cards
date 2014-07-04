//
//  CardCounter.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardCounter.h"
#import "Card.h"

#if DEBUG
@interface CardCounter()
@property NSString* code;
@end
#endif

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
#if DEBUG
    cc.code = card.code;
#endif
    cc.count = count;
    cc.showAltArt = NO;
        
    return cc;
}

-(void) setCount:(NSUInteger)count
{
    self->_count = count;
    
#if DEBUG
    NSAssert([self.code isEqualToString:self->_card.code], @"code mismath");
#endif
}

#if DEBUG
-(Card*) card
{
    NSAssert([self.code isEqualToString:self->_card.code], @"code mismath");
    return self->_card;
}
#endif

#pragma mark NSCoding

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.showAltArt = [decoder decodeBoolForKey:@"altArt"];
        NSString* code = [decoder decodeObjectForKey:@"card"];
        _card = [Card cardByCode:code];
#if DEBUG
        _code = code;
#endif
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
