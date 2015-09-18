//
//  DeckState.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@interface DeckState : NSObject

+(NSString*) labelFor:(NRDeckState) state;
+(NSString*) buttonLabelFor:(NRDeckState) state;

@end
