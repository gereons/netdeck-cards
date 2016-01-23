//
//  CardTypeStats.h
//  Net Deck
//
//  Created by Gereon Steffens on 17.02.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@interface CardTypeStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(CardTypeStats*) initWithDeck:(Deck*)deck;

@property (readonly) CPTGraphHostingView* hostingView;

@end
