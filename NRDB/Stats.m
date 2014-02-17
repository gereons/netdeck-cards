//
//  Stats.m
//  NRDB
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@implementation Stats

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    // 1626c4
    UIColor* base = [UIColor colorWithRed:0x16/256.0 green:0x26/256.0 blue:0xc4/256.0 alpha:1];
    CGFloat hue, brightness, saturation, alpha;
    [base getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    hue *= 360.0;
    float step = 360.0 / self.tableData.sections.count;
    for (int i=0; i<index; ++i)
    {
        hue += step;
        if (hue > 360.0) hue -= 360.0;
    }
    
    UIColor* col = [UIColor colorWithHue:hue/360.0 saturation:saturation brightness:brightness alpha:alpha];
    
    return [CPTFill fillWithColor:[CPTColor colorWithCGColor:col.CGColor]];
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
