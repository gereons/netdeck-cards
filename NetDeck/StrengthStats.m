//
//  StrengthStats.m
//  Net Deck
//
//  Created by Gereon Steffens on 15.02.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "StrengthStats.h"

@implementation StrengthStats

-(StrengthStats*) initWithDeck:(Deck *)deck
{
    if ((self = [super init]))
    {
        // calculate strength distribution
        NSMutableDictionary* strengths = [NSMutableDictionary dictionary];
        for (CardCounter* cc in deck.cards)
        {
            NSInteger str = cc.card.strength;
            if (str != -1)
            {
                NSNumber* n = [strengths objectForKey:@(str)];
                int prev = n == nil ? 0 : [n intValue];
                n = @(prev + cc.count);
                [strengths setObject:n forKey:@(str)];
            }
        }
        
        NSArray* sections = [[strengths allKeys] sortedArrayUsingComparator:^(NSNumber* n1, NSNumber* n2) { return [n1 compare:n2]; }];
        NSMutableArray* values = [NSMutableArray array];
        for (NSNumber*n in sections)
        {
            [values addObject:[strengths objectForKey:n]];
        }
        NSAssert(sections.count == values.count, @"");
        self.tableData = [[TableData alloc] initWithSections:sections andValues:values];
    }
    return self;
}

-(CGFloat) height
{
    return self.tableData.sections.count == 0 ? 0 : 300;
}

-(CPTGraphHostingView*) hostingView
{
    return [self hostingViewForDelegate:self identifier:@"Strength"];
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
    
    NSNumber* strength = [self.tableData.sections objectAtIndex:index];
    NSNumber* cards = [self.tableData.values objectAtIndex:index];
    
    NSString* str = nil;
    int c = [cards intValue];
    if (c > 0)
    {
        str = [NSString stringWithFormat:l10n(@"Strength %d\n%d %@"), [strength intValue], c, CARDS(c)];
    }
    
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:str style:labelText];
}

@end
