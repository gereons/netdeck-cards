//
//  CardTypeStats.h
//  NRDB
//
//  Created by Gereon Steffens on 17.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stats.h"

@class Deck;

@interface CardTypeStats : Stats <CPTPlotDataSource, CPTPlotDelegate>

-(CardTypeStats*) initWithDeck:(Deck*)deck;

@property (readonly) CPTGraphHostingView* hostingView;

@end