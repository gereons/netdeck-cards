//
//  UIAlertAction+NetDeck.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.10.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface UIAlertAction(NetDeck)

+(UIAlertAction*) cancelAction:(void (^)(UIAlertAction *action))handler;
+(UIAlertAction*) actionWithTitle:(NSString*)title handler:(void (^)(UIAlertAction *action))handler;

@end

@interface UIAlertController(NetDeck)

-(void) show;
-(void) present:(BOOL)animated completion:^(void)completion

@end
