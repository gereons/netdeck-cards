//
//  NRNavigationController.h
//  NRDB
//
//  Created by Gereon Steffens on 30.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DeckListViewController;

@interface NRNavigationController : UINavigationController <UINavigationBarDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@property DeckListViewController* deckListViewController;

@end
