//
//  InfluenceStats.h
//  NRDB
//
//  Created by Gereon Steffens on 17.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@class Deck;

@interface InfluenceStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(InfluenceStats*) initWithDeck:(Deck*)deck;
@property (readonly) CPTGraphHostingView* hostingView;

@end
