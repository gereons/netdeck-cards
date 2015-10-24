//
//  TableData.m
//  Net Deck
//
//  Created by Gereon Steffens on 13.01.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "TableData.h"

@implementation TableData

-(id) initWithSections:(NSArray*)sections andValues:(NSArray*)values;
{
    if ((self = [super init]))
    {
        NSAssert(sections.count == values.count, @"sections/values count mismatch");
        self.sections = sections;
        self.values = values;
        self.collapsedSections = nil;
    }
    return self;
}

-(id) initWithValues:(NSArray *)values
{
    return [self initWithSections:@[ @"" ] andValues:@[values] ];
}

@end
