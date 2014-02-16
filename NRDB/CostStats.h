//
//  CostStats.h
//  NRTM
//
//  Created by Gereon Steffens on 23.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stats.h"

@class Deck;

@interface CostStats : Stats <CPTPlotDataSource>

-(CostStats*) initWithDeck:(Deck*)deck;
@property (readonly) CPTGraphHostingView* hostingView;
@property (readonly) CGFloat height;

@end
