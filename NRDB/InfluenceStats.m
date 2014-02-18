//
//  InfluenceStats.m
//  NRDB
//
//  Created by Gereon Steffens on 17.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "InfluenceStats.h"
#import "Deck.h"
#import "Faction.h"

@implementation InfluenceStats

-(InfluenceStats*) initWithDeck:(Deck *)deck
{
    if ((self = [super init]))
    {
        // calculate influence distribution
        NSMutableDictionary* influence = [NSMutableDictionary dictionary];
        for (CardCounter* cc in deck.cards)
        {
            int inf = [deck influenceFor:cc];
            if (inf > 0)
            {
                NSString* faction = [Faction name:cc.card.faction];
                
                NSNumber* n = [influence objectForKey:faction];
                int prev = n == nil ? 0 : [n intValue];
                n = @(prev + inf);
                [influence setObject:n forKey:faction];
            }
        }
        
        NSArray* sections = [[influence allKeys] sortedArrayUsingComparator:^(NSString* s1, NSString* s2) { return [s1 compare:s2]; }];
        NSMutableArray* values = [NSMutableArray array];
        for (NSString*s in sections)
        {
            [values addObject:[influence objectForKey:s]];
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
    
    NSString* faction = [self.tableData.sections objectAtIndex:index];
    NSNumber* inf = [self.tableData.values objectAtIndex:index];
    
    NSString* str = nil;
    if ([inf intValue] > 0)
    {
        str = [NSString stringWithFormat:@"%@: %d", faction, [inf intValue]];
    }
    
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:str style:labelText];
}

@end

