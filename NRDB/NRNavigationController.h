//
//  NRNavigationController.h
//  Net Deck
//
//  Created by Gereon Steffens on 30.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "NRDeckEditor.h"

@interface NRNavigationController : UINavigationController <UINavigationBarDelegate, UIGestureRecognizerDelegate>

@property (weak) id<NRDeckEditor> deckEditor;

@end
