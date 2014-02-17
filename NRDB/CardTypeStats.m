//
//  CardTypeStats.m
//  NRDB
//
//  Created by Gereon Steffens on 17.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardTypeStats.h"
#import "Deck.h"

@interface CardTypeStats()
@property int deckSize;
@end

@implementation CardTypeStats

-(CardTypeStats*) initWithDeck:(Deck *)deck
{
    if ((self = [super init]))
    {
        // calculate ice type distribution
        NSMutableDictionary* types = [NSMutableDictionary dictionary];
        for (CardCounter* cc in deck.cards)
        {
            NSString* type = cc.card.typeStr;
            
            if (cc.card.type == NRCardTypeProgram && [cc.card.subtypes containsObject:@"Icebreaker"])
            {
                type = @"Icebreaker";
            }
            NSNumber* n = [types objectForKey:type];
            int prev = n == nil ? 0 : [n intValue];
            n = @(prev + cc.count);
            [types setObject:n forKey:type];
        }
        
        NSArray* sections = [[types allKeys] sortedArrayUsingComparator:^(NSString* s1, NSString* s2) { return [s1 compare:s2]; }];
        NSMutableArray* values = [NSMutableArray array];
        for (NSNumber*n in sections)
        {
            [values addObject:[types objectForKey:n]];
        }
        NSAssert(sections.count == values.count, @"");
        self.tableData = [[TableData alloc] initWithSections:sections andValues:values];
        self.deckSize = deck.size;
    }
    return self;
}

-(CPTGraphHostingView*) hostingView
{
    return [self hostingViewForDelegate:self identifier:@"Card Type"];
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
        float pct = [cards intValue] * 100.0 / _deckSize;
        
        str = [NSString stringWithFormat:@"%@: %d\n%.1f%%", type, [cards intValue], pct];
    }
    
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:str style:labelText];
}

@end


