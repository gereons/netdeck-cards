//
//  Stats.m
//  Net Deck
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@implementation Stats

#define RGB_COLOR(R,G,B) [UIColor colorWithRed:(R/255.0) green:(G/255.0) blue:(B/255.0) alpha:.8]

static NSArray* colors;

+(void) initialize
{
    colors = @[ RGB_COLOR(231,13,0),
       RGB_COLOR(240,9,254),
       RGB_COLOR(60,2,243),
       RGB_COLOR(0,250,214),
       RGB_COLOR(8,227,34),
       RGB_COLOR(192,253,2),
       RGB_COLOR(243,183,8),
       RGB_COLOR(254,118,13),
       RGB_COLOR(235,80,71),
       RGB_COLOR(204,72,212),
       RGB_COLOR(114,74,246),
       RGB_COLOR(75,143,223),
       RGB_COLOR(76,251,224),
       RGB_COLOR(77,228,94),
       RGB_COLOR(212,253,77),
       RGB_COLOR(246,198,62),
       RGB_COLOR(212,122,53) ];
}


-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    index = index % colors.count;
    UIColor* color = [colors objectAtIndex:index];
    return [CPTFill fillWithColor:[CPTColor colorWithCGColor:color.CGColor]];
}

-(CGFloat) height
{
    return self.tableData.sections.count == 0 ? 0 : 300;
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

-(CPTGraphHostingView*) hostingViewForDelegate:(id<CPTPlotDataSource, CPTPlotDelegate>)delegate identifier:(NSString*)identifier
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
    pieChart.dataSource = delegate;
    pieChart.delegate = delegate;
    pieChart.pieRadius = (hostView.bounds.size.height * 0.7) / 2;
    pieChart.identifier = identifier;
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

@end
