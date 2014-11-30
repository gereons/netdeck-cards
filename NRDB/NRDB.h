//
//  NRDB.h
//  NRDB
//
//  Created by Gereon Steffens on 20.06.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface NRDB : NSObject

+(NRDB*) sharedInstance;
+(void) clearSettings;

typedef void (^AuthCompletionBlock)(BOOL ok);
typedef void (^DecklistCompletionBlock)(NSArray* decks);
typedef void (^SaveCompletionBlock)(BOOL ok, NSString* deckId);
typedef void (^LoadCompletionBlock)(BOOL ok, Deck* deck);

-(void)authorizeWithCode:(NSString*)code completion:(AuthCompletionBlock)completionBlock;

-(void)decklist:(DecklistCompletionBlock)completionBlock;

-(void)loadDeck:(Deck*)deck completion:(LoadCompletionBlock)completionBlock;

-(void)saveDeck:(Deck*)deck completion:(SaveCompletionBlock)completionBlock;
-(void)publishDeck:(Deck*)deck completion:(SaveCompletionBlock)completionBlock;

-(void)refreshAuthentication;
-(void)stopRefresh;

-(void)updateDeckMap:(NSArray*) decks;
-(NSString*) filenameForId:(NSString*)deckId;
-(void) deleteDeck:(NSString*)filename;

@end
