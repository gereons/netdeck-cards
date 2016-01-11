//
//  CostStats.h
//  NRTM
//
//  Created by Gereon Steffens on 23.11.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@interface CostStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(CostStats*) initWithDeck:(Deck*)deck;
@property (readonly) CPTGraphHostingView* hostingView;

@end
