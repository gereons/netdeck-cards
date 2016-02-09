//
//  UIAlert+NetDeck.m
//  Net Deck
//
//  Created by Gereon Steffens on 28.10.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "UIAlert+NetDeck.h"

@implementation UIAlertAction (NetDeck)

+(UIAlertAction*) cancelAction:(void (^)(UIAlertAction *action))handler
{
    NSString* title = IS_IPAD ? @"" : l10n(@"Cancel");
    return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleCancel handler:handler];
}

+(UIAlertAction*) cancelAlertAction:(void (^)(UIAlertAction *action))handler
{
    NSString* title = l10n(@"Cancel");
    return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleCancel handler:handler];
}

+(UIAlertAction*) actionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler
{
    return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:handler];
}

@end

// see http://stackoverflow.com/questions/26554894/how-to-present-uialertcontroller-when-not-in-a-view-controller
@implementation UIAlertController(NetDeck)

+(void) alertWithTitle:(NSString*)title message:(NSString*)msg button:(NSString*)button {
    UIAlertController* alert = [UIAlertController alertWithTitle:title message:msg];
    [alert addAction:[UIAlertAction actionWithTitle:button handler:nil]];
    [alert show];
}

+(UIAlertController*) alertWithTitle:(NSString*)title message:(NSString*)msg {
    return [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
}

+(UIAlertController*) actionSheetWithTitle:(NSString*)title message:(NSString*)msg {
    return [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleActionSheet];
}

-(void) show {
    [self present:NO completion:nil];
}

-(void) present:(BOOL)animated completion:(void (^ __nullable)(void))completion {
    UIViewController* rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [self presentFromController:rootVC animated:animated completion:completion];
}

-(void) presentFromController:(UIViewController*)controller animated:(BOOL)animated completion:(void (^ __nullable)(void))completion {
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navVC = (UINavigationController*)controller;
        if ([navVC visibleViewController]) {
            [self presentFromController:navVC.visibleViewController animated:animated completion:completion];
        }
    } else if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabVC = (UITabBarController*)controller;
        UIViewController* selected = [tabVC selectedViewController];
        if (selected) {
            [self presentFromController:selected animated:animated completion:completion];
        }
    } else {
        [controller presentViewController:self animated:animated completion:completion];
    }
}

@end