//
//  StrengthStats.h
//  Net Deck
//
//  Created by Gereon Steffens on 15.02.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@class Deck;

@interface StrengthStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(StrengthStats*) initWithDeck:(Deck*)deck;

@property (readonly) CPTGraphHostingView* hostingView;

@end
