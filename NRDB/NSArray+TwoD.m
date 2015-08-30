//
//  NSArray+TwoD.m
//  Net Deck
//
//  Created by Gereon Steffens on 17.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "NSArray+TwoD.h"

@implementation NSArray (TwoD)

-(id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == nil)
    {
        return nil;
    }
    
    NSAssert(indexPath.section < self.count, @"section out of range 0..%ld", (long)self.count);
    NSArray* arr = self[indexPath.section];
    NSAssert([arr isKindOfClass:[NSArray class]], @"element at %ld is not an array", (long)indexPath.section);
    NSAssert(indexPath.row < arr.count, @"row out of range 0..%ld", (long)arr.count);
    return arr[indexPath.row];
}


@end
