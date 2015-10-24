//
//  IceTypeStats.h
//  Net Deck
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@class Deck;

@interface IceTypeStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(IceTypeStats*) initWithDeck:(Deck*)deck;

@property (readonly) CPTGraphHostingView* hostingView;

@end