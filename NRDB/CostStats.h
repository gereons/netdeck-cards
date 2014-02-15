//
//  CostStats.h
//  NRTM
//
//  Created by Gereon Steffens on 23.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CorePlot-CocoaTouch.h"

@class Deck;

@interface CostStats : NSObject <CPTPlotDataSource>

+(CostStats*) sharedInstance;

-(CPTGraphHostingView*) hostingViewForDeck:(Deck*)deck;
@property (readonly) CGFloat height;

@end
