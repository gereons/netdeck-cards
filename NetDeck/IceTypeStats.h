//
//  IceTypeStats.h
//  Net Deck
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@interface IceTypeStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(IceTypeStats*) initWithDeck:(Deck*)deck;

@property (readonly) CPTGraphHostingView* hostingView;

@end