//
//  Stats.h
//  NRDB
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CorePlot-CocoaTouch.h>
#import "TableData.h"

@interface Stats : NSObject

@property TableData* tableData;
@property (readonly) CGFloat height;

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index;
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot;
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index;
-(CPTGraphHostingView*) hostingViewForDelegate:(id<CPTPlotDataSource, CPTPlotDelegate>)delegate identifier:(NSString*)identifier;

@end
