//
//  DeckImport.h
//  Net Deck
//
//  Created by Gereon Steffens on 01.02.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface DeckImport : NSObject

+(void) updateCount;
+(void) checkClipboardForDeck;

+(void) importDeckFromLocalUrl:(NSURL*)url;

@end
