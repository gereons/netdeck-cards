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
    if (indexPath == nil) {
        return nil;
    }
    
    NSAssert(indexPath.section < self.count, @"section %ld out of range 0..%ld", (long)indexPath.section, (long)self.count);
    if (indexPath.section >= self.count) {
        return nil;
    }
    
    NSArray* arr = self[indexPath.section];
    NSAssert([arr isKindOfClass:[NSArray class]], @"element at %ld is not an array", (long)indexPath.section);
    NSAssert(indexPath.row < arr.count, @"row %ld out of range 0..%ld", (long)indexPath.row, (long)arr.count);
    if (indexPath.row >= arr.count) {
        return nil;
    }
    
    return arr[indexPath.row];
}


@end
