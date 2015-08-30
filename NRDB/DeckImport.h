//
//  DeckImport.h
//  Net Deck
//
//  Created by Gereon Steffens on 01.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface DeckImport : NSObject

+(void) updateCount;
+(void) checkClipboardForDeck;

+(void) importDeckFromLocalUrl:(NSURL*)url;

@end
