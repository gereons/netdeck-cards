//
//  DeckImport.h
//  NRDB
//
//  Created by Gereon Steffens on 01.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SDCAlertView.h>

@class Deck;

@interface DeckImport : NSObject<SDCAlertViewDelegate>

+(void) updateCount;
+(void) checkClipboardForDeck;

@end
