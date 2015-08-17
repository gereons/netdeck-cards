//
//  NSArray+Checked.m
//  NRDB
//
//  Created by Gereon Steffens on 17.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "NSArray+Checked.h"

@implementation NSArray (Checked)

-(id)get:(NSUInteger)index
{
    return index < self.count ? self[index] : nil;
}

-(id)get2d:(NSIndexPath *)indexPath
{
    NSArray* arr = [self get:indexPath.section];
    NSAssert([arr isKindOfClass:[NSArray class]], @"not an array");
    return [arr get:indexPath.row];
}

@end
