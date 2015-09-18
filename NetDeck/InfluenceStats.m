//
//  InfluenceStats.m
//  Net Deck
//
//  Created by Gereon Steffens on 17.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "InfluenceStats.h"
#import "Deck.h"
#import "Faction.h"
@interface InfluenceStats()
@property NSMutableDictionary* colors;
@end
@implementation InfluenceStats

-(InfluenceStats*) initWithDeck:(Deck *)deck
{
    if ((self = [super init]))
    {
        self.colors = [NSMutableDictionary dictionary];
        // calculate influence distribution
        NSMutableDictionary* influence = [NSMutableDictionary dictionary];
        for (CardCounter* cc in deck.cards)
        {
            NSUInteger inf = [deck influenceFor:cc];
            if (inf > 0)
            {
                NSString* faction = [Faction name:cc.card.faction];
                
                NSNumber* n = [influence objectForKey:faction];
                int prev = n == nil ? 0 : [n intValue];
                n = @(prev + inf);
                [influence setObject:n forKey:faction];
                
                [self.colors setObject:cc.card.factionColor forKey:faction];
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
    return [self hostingViewForDelegate:self identifier:@"Influence"];
}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    NSString* faction = [self.tableData.sections objectAtIndex:index];
    
    UIColor* color = [self.colors objectForKey:faction];
    return [CPTFill fillWithColor:[CPTColor colorWithCGColor:color.CGColor]];
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

