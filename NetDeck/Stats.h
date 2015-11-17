//
//  Stats.h
//  Net Deck
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@import CorePlot;

@interface Stats : NSObject

@property TableData* tableData;
@property (readonly) CGFloat height;

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index;
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot;
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index;
-(CPTGraphHostingView*) hostingViewForDelegate:(id<CPTPlotDataSource, CPTPlotDelegate>)delegate identifier:(NSString*)identifier;

#define CARDS(x)    ((x)==1?l10n(@"card"):l10n(@"cards"))
#define CREDITS(x)  ((x)==1?l10n(@"credit"):l10n(@"credits"))

@end
