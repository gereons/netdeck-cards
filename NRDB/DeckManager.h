//
//  DeckManager.h
//  NRDB
//
//  Created by Gereon Steffens on 18.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Deck;

@interface DeckManager : NSObject

// save deck in new file, return full pathname
+(NSString*) saveDeck:(Deck*)decl;

// save deck in given file
+(void) saveDeck:(Deck*)decl toPath:(NSString*)pathname;

// load deck from given file
+(Deck*) loadDeckFromPath:(NSString*)pathname;

// remove all saved decks
+(void) removeAll;

// remove a file
+(void) removeFile:(NSString*)pathname;

+(NSMutableArray*) decksForRole:(NRRole)role;

+(NSString*) directoryForRole:(NRRole)role;

@end
