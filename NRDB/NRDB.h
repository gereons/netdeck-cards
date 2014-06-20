//
//  NRDB.h
//  NRDB
//
//  Created by Gereon Steffens on 20.06.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRDB : NSObject

+(NRDB*) sharedInstance;

typedef void (^LoginCompletionBlock)(BOOL ok);
typedef void (^DecklistCompletionBlock)(NSArray* decks);

-(void)login:(LoginCompletionBlock)completionBlock;
-(void)decklist:(DecklistCompletionBlock)completionBlock;

@end
