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

@implementation UIAlertController(NetDeck)

-(void) present:(BOOL)animated completion:(^(void))completion {
    UIViewController* rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (rootVC != nil) {
        [self presentFromController:rootVC animated:animated completion:completion];
    }
}

/*
private func presentFromController(controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
    if let navVC = controller as? UINavigationController,
        let visibleVC = navVC.visibleViewController {
            presentFromController(visibleVC, animated: animated, completion: completion)
        } else
            if let tabVC = controller as? UITabBarController,
                let selectedVC = tabVC.selectedViewController {
                    presentFromController(selectedVC, animated: animated, completion: completion)
                } else {
                    controller.presentViewController(self, animated: animated, completion: completion);
                }
}
 */

-(void) presentFromController:(UIViewController*)controller animated:(BOOL)animated completion:^(void)completion {
    
}

@end