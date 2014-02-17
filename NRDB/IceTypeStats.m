//
//  IceTypeStats.m
//  NRDB
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "IceTypeStats.h"
#import "Deck.h"

@implementation IceTypeStats

-(IceTypeStats*) initWithDeck:(Deck *)deck
{
    NSArray* iceTypes = @[ @"Code Gate", @"Sentry" , @"Barrier" ];
    
    if ((self = [super init]))
    {
        // calculate ice type distribution
        NSMutableDictionary* ice = [NSMutableDictionary dictionary];
        for (CardCounter* cc in deck.cards)
        {
            if (cc.card.type == NRCardTypeIce)
            {
                for (NSString* subtype in cc.card.subtypes)
                {
                    if ([iceTypes containsObject:subtype])
                    {
                        NSNumber* n = [ice objectForKey:subtype];
                        int prev = n == nil ? 0 : [n intValue];
                        n = @(prev + cc.count);
                        [ice setObject:n forKey:subtype];
                    }
                }
            }
        }
        
        NSArray* sections = [[ice allKeys] sortedArrayUsingComparator:^(NSString* s1, NSString* s2) { return [s1 compare:s2]; }];
        NSMutableArray* values = [NSMutableArray array];
        for (NSNumber*n in sections)
        {
            [values addObject:[ice objectForKey:n]];
        }
        NSAssert(sections.count == values.count, @"");
        self.tableData = [[TableData alloc] initWithSections:sections andValues:values];
    }
    return self;
}

-(CPTGraphHostingView*) hostingView
{
    return [self hostingViewForDelegate:self identifier:@"Ice Type"];
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
    
    NSString* type = [self.tableData.sections objectAtIndex:index];
    NSNumber* cards = [self.tableData.values objectAtIndex:index];
    
    NSString* str = nil;
    if ([cards intValue] > 0)
    {
        str = [NSString stringWithFormat:@"%@\n%d cards", type, [cards intValue]];
    }
    
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:str style:labelText];
}

@end

