//
//  StrengthStats.h
//  NRDB
//
//  Created by Gereon Steffens on 15.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CorePlot-CocoaTouch.h"

@class Deck;

@interface StrengthStats : NSObject <CPTPlotDataSource>

+(StrengthStats*) sharedInstance;

-(CPTGraphHostingView*) hostingViewForDeck:(Deck*)deck;
@property (readonly) CGFloat height;

@end
