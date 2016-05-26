//
//  NRTypes.h
//  Net Deck
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#ifndef NRTypes_h
#define NRTypes_h

#define CHECKED_TITLE(str, cond)    [NSString stringWithFormat:@"%@%@", str, cond ? @" ✓" : @""]

#define KEYCMD(letter, modifiers, sel, title) [UIKeyCommand keyCommandWithInput:letter modifierFlags:modifiers action:@selector(sel) discoverabilityTitle:title] 

#endif
