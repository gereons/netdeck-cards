//
//  InfluenceStats.h
//  Net Deck
//
//  Created by Gereon Steffens on 17.02.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@class Deck;

@interface InfluenceStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(InfluenceStats*) initWithDeck:(Deck*)deck;
@property (readonly) CPTGraphHostingView* hostingView;

@end
