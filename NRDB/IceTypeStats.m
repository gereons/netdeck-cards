//
//  IceTypeStats.m
//  Net Deck
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "IceTypeStats.h"
#import "Deck.h"

@interface IceTypeStats()
@property NSUInteger iceCount;
@end

@implementation IceTypeStats

-(IceTypeStats*) initWithDeck:(Deck *)deck
{
    if ((self = [super init]))
    {
        self.iceCount = 0;
        
        // calculate ice type distribution
        NSMutableDictionary* ice = [NSMutableDictionary dictionary];
        
        for (CardCounter* cc in deck.cards)
        {
            if (cc.card.type != NRCardTypeIce)
            {
                continue;
            }
            self.iceCount += cc.count;
            NSString* iceType = cc.card.iceType;
            
            NSNumber* n = [ice objectForKey:iceType];
            int cnt = n==nil ? 0 : [n intValue];
            n = @(cnt + cc.count);
            [ice setObject:n forKey:iceType];
        }

        NSArray* sections = [[ice allKeys] sortedArrayUsingComparator:^(NSString* s1, NSString* s2) {
            return [s1 compare:s2];
        }];
        NSMutableArray* values = [NSMutableArray array];
        
        for (NSString*s in sections)
        {
            [values addObject:[ice objectForKey:s]];
        }
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
        float pct = [cards intValue] * 100.0 / self.iceCount;
        str = [NSString stringWithFormat:@"%@: %d\n%.1f%%", type, [cards intValue], pct];
    }
    
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:str style:labelText];
}

@end

