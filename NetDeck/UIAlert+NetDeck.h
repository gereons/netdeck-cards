//
//  UIAlert+NetDeck.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.10.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertAction(NetDeck)

// cancelAction can only be used a) on iPhone and b) for iPad action sheets
+(instancetype) cancelAction:(void (^ __nullable)(UIAlertAction *action))handler;
+(instancetype) cancelAlertAction:(void (^ __nullable)(UIAlertAction *action))handler;
+(instancetype) actionWithTitle:(NSString*)title handler:(void (^ __nullable)(UIAlertAction *action))handler;

@end

@interface UIAlertController(NetDeck)

+(void) alertWithTitle:(NSString* __nullable)title message:(NSString* __nullable)msg button:(NSString*)button;

-(void) show; // shortcut for [self present:NO completion:nil]
-(void) present:(BOOL)animated completion:(void (^ __nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
