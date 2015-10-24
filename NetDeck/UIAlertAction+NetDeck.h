//
//  UIAlertAction+NetDeck.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.10.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface UIAlertAction(NetDeck)

+(UIAlertAction*) cancelAction:(void (^)(UIAlertAction *action))handler;
+(UIAlertAction*) actionWithTitle:(NSString*)title handler:(void (^)(UIAlertAction *action))handler;

@end
