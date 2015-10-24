//
//  DeckState.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.05.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface DeckState : NSObject

+(NSString*) labelFor:(NRDeckState) state;
+(NSString*) buttonLabelFor:(NRDeckState) state;

@end
