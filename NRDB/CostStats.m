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

-(CGFloat) height
{
    return self.tableData.sections.count == 0 ? 0 : 300;
}

-(CPTGraphHostingView*) hostingView
{
    // hostView
    CGRect rect = CGRectMake(0, 0, 500, self.height);
    CPTGraphHostingView *hostView = [[CPTGraphHostingView alloc] initWithFrame:rect];
    hostView.allowPinchScaling = NO;
    
    // graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:hostView.bounds];
    hostView.hostedGraph = graph;
    graph.paddingLeft = 0.0f;
    graph.paddingTop = 0.0f;
    graph.paddingRight = 0.0f;
    graph.paddingBottom = 0.0f;
    graph.axisSet = nil;
    
    // set theme
    CPTTheme* selectedTheme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:selectedTheme];
    
    // 2 - Set up text style
    //    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    //    textStyle.color = [CPTColor blackColor];
    //    textStyle.fontName = @"Helvetica-Bold";
    //    textStyle.fontSize = 20.0f;
    //    // 3 - Configure title
    //    NSString *title = @"Games";
    //    // graph.title = title;
    //    graph.titleTextStyle = textStyle;
    //    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    //    graph.titleDisplacement = CGPointMake(0.0f, -2.0f);
    graph.plotAreaFrame.borderLineStyle = nil;
    
    // configure chart
    CPTPieChart *pieChart = [[CPTPieChart alloc] init];
    pieChart.dataSource = self;
    pieChart.delegate = self;
    pieChart.pieRadius = (hostView.bounds.size.height * 0.7) / 2;
    pieChart.identifier = @"Cost";
    pieChart.startAngle = M_PI_2;
    pieChart.sliceDirection = CPTPieDirectionClockwise;
    // create gradient
    CPTGradient *overlayGradient = [[CPTGradient alloc] init];
    overlayGradient.gradientType = CPTGradientTypeRadial;
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.9];
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.2] atPosition:1.0];
    pieChart.overlayFill = [CPTFill fillWithGradient:overlayGradient];
    // add chart to graph
    [graph addPlot:pieChart];
    
    // configure legend
    CPTLegend *theLegend = [CPTLegend legendWithGraph:graph];
    theLegend.numberOfColumns = 3;
    theLegend.fill = [CPTFill fillWithColor:[CPTColor whiteColor]];
    theLegend.borderLineStyle = nil; // [CPTLineStyle lineStyle];
    theLegend.cornerRadius = 5.0;
    theLegend.swatchCornerRadius = 5;
    // add legend to graph
    // graph.legend = theLegend;
    graph.legendAnchor = CPTRectAnchorBottom;
    graph.legendDisplacement = CGPointMake(0.0, 5.0);
    
    return hostView;
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return self.tableData.sections.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    return [self.tableData.values objectAtIndex:index];
}

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
    if ([cards intValue] > 0)
    {
        str = [NSString stringWithFormat:@"%d credits\n%d cards", [cost intValue], [cards intValue]];
    }
    
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:str style:labelText];
}

@end
