//
//  DeckManager.h
//  Net Deck
//
//  Created by Gereon Steffens on 18.03.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface xDeckManager : NSObject

// save deck, create new file if deck.filename is nil
+(void) saveDeck:(Deck*)deck;

// save deck in given file
// +(void) saveDeck:(Deck*)deck toPath:(NSString*)pathname;

// load deck from given file
+(Deck*) loadDeckFromPath:(NSString*)pathname;

// remove all saved decks
+(void) xxremoveAll;

// remove a file
+(void) removeFile:(NSString*)pathname;

+(void) resetModificationDate:(Deck*)deck;

+(NSMutableArray<Deck*>*) decksForRole:(NRRole)role;

+(NSString*) directoryForRole:(NRRole)role;

@end
