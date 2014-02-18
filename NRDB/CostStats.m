//
//  CostStats.m
//  NRTM
//
//  Created by Gereon Steffens on 23.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CostStats.h"
#import "Deck.h"

@implementation CostStats

-(CostStats*) initWithDeck:(Deck *)deck
{
    if ((self = [super init]))
    {
        // calculate cost distribution
        NSMutableDictionary* costs = [NSMutableDictionary dictionary];
        for (CardCounter* cc in deck.cards)
        {
            int cost = cc.card.cost;
            if (cost != -1)
            {
                NSNumber* n = [costs objectForKey:@(cost)];
                int prev = n == nil ? 0 : [n intValue];
                n = @(prev + cc.count);
                [costs setObject:n forKey:@(cost)];
            }
        }
        
        NSArray* sections = [[costs allKeys] sortedArrayUsingComparator:^(NSNumber* n1, NSNumber* n2) { return [n1 compare:n2]; }];
        NSMutableArray* values = [NSMutableArray array];
        for (NSNumber*n in sections)
        {
            [values addObject:[costs objectForKey:n]];
        }
        NSAssert(sections.count == values.count, @"");
        self.tableData = [[TableData alloc] initWithSections:sections andValues:values];
    }
    return self;
}

-(CPTGraphHostingView*) hostingView
{
    return [self hostingViewForDelegate:self identifier:@"Cost"];
}

#pragma mark - CPTPlotDataSource methods

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    static CPTMutableTextStyle *labelText = nil;
    
    if (!labelText)
    {
        labelText = [[CPTMutableTextStyle alloc] init];
        labelText.color = [CPTColor blackColor];
    }
    
    NSNumber* cost = [self.tableData.sections objectAtIndex:index];
    NSNumber* cards = [self.tableData.values objectAtIndex:index];
    
    NSString* str = nil;
    int c = [cards intValue];
    if (c > 0)
    {
        str = [NSString stringWithFormat:@"%d credits\n%d %@", [cost intValue], c, CARDS(c)];
    }
    
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:str style:labelText];
}

@end
