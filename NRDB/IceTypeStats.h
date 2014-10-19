//
//  IceTypeStats.h
//  NRDB
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@class Deck;

@interface IceTypeStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(IceTypeStats*) initWithDeck:(Deck*)deck;

@property (readonly) CPTGraphHostingView* hostingView;

@end