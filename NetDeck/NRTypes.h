//
//  NRTypes.h
//  Net Deck
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#ifndef NRTypes_h
#define NRTypes_h

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define CHECKED_TITLE(str, cond)    [NSString stringWithFormat:@"%@%@", str, cond ? @" ✓" : @""]

#define IS_IPAD         ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_IPHONE       ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)

#define SCREEN_WIDTH        ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT       ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH   (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH   (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4         (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)

#define IOS9_KEYCMD         [[UIKeyCommand class] respondsToSelector:@selector(keyCommandWithInput:modifierFlags:action:discoverabilityTitle:)]
#define KEYCMD(letter, modifiers, sel, title) ((IOS9_KEYCMD) ? \
    [UIKeyCommand keyCommandWithInput:letter modifierFlags:modifiers action:@selector(sel) discoverabilityTitle:title] : \
    [UIKeyCommand keyCommandWithInput:letter modifierFlags:modifiers action:@selector(sel)])

extern NSString* const kANY;

#endif
