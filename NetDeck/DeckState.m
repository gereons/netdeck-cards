//
//  DeckState.m
//  Net Deck
//
//  Created by Gereon Steffens on 28.05.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "DeckState.h"

@implementation DeckState

static NSDictionary* stateStr;

+(void) initialize
{
    stateStr = @{
        @(NRDeckStateNone): l10n(@"All"),
        @(NRDeckStateRetired): l10n(@"Retired"),
        @(NRDeckStateTesting): l10n(@"Testing"),
        @(NRDeckStateActive): l10n(@"Active")
    };
}

+(NSString*) labelFor:(NRDeckState) state
{
    return stateStr[@(state)];
}

+(NSString*) buttonLabelFor:(NRDeckState) state
{
    return [NSString stringWithFormat:@"%@ ▾", stateStr[@(state)]];
}

@end
