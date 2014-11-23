//
//  DeckChange.m
//  NRDB
//
//  Created by Gereon Steffens on 22.11.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckChange.h"
#import "Card.h"

@implementation DeckChange

+(DeckChange*) forCode:(NSString*)code copies:(NSInteger)copies
{
    DeckChange* dc = [[DeckChange alloc] init];
    dc->_code = code;
    dc->_count = ABS(copies);
    dc->_op = copies < 0 ? NRDeckChangeRemoveCard : NRDeckChangeAddCard;
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
        self->_op = [decoder decodeIntegerForKey:@"op"];
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
