//
//  NRNavigationController.h
//  NRDB
//
//  Created by Gereon Steffens on 30.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class DeckListViewController;

@interface NRNavigationController : UINavigationController <UINavigationBarDelegate, UIGestureRecognizerDelegate>

@property (weak) DeckListViewController* deckListViewController;

@end
