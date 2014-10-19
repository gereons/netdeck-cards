//
//  DeckExport.h
//  NRDB
//
//  Created by Gereon Steffens on 05.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface DeckExport : NSObject

+(void) asOctgn:(Deck*)deck autoSave:(BOOL)autoSave;

+(NSString*) asBBCodeString:(Deck*)deck;
+(NSString*) asMarkdownString:(Deck*)deck;
+(NSString*) asPlaintextString:(Deck*)deck;

+(void) asBBCode:(Deck*)deck;
+(void) asMarkdown:(Deck*)deck;
+(void) asPlaintext:(Deck*)deck;

@end
