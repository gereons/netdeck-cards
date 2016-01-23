//
//  UIAlertAction+NetDeck.m
//  Net Deck
//
//  Created by Gereon Steffens on 28.10.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "UIAlertAction+NetDeck.h"

@implementation UIAlertAction (NetDeck)

+(UIAlertAction*) cancelAction:(void (^)(UIAlertAction *action))handler
{
    NSString* title = IS_IPAD ? @"" : l10n(@"Cancel");
    return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleCancel handler:handler];
}

+(UIAlertAction*) actionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler
{
    return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:handler];
}

@end