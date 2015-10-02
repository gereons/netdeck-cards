//
//  UIFont+monospacedDigits.m
//  NetDeck
//
//  Created by Gereon Steffens on 02.10.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

#import "UIFont+monospacedDigits.h"

@implementation UIFont(monospaceDigits)

static BOOL ios9;

+(void) initialize
{
    ios9 = [[UIFont class] respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)];
}

+(UIFont*) md_systemFontOfSize:(CGFloat)fontSize
{
    if (ios9)
    {
        return [UIFont monospacedDigitSystemFontOfSize:fontSize weight:UIFontWeightRegular];
    }
    else
    {
        return [UIFont systemFontOfSize:fontSize];
    }
}

+(UIFont*) md_boldSystemFontOfSize:(CGFloat)fontSize
{
    if (ios9)
    {
        return [UIFont monospacedDigitSystemFontOfSize:fontSize weight:UIFontWeightBold];
    }
    else
    {
        return [UIFont boldSystemFontOfSize:fontSize];
    }
}

+(UIFont*) md_mediumSystemFontOfSize:(CGFloat)fontSize
{
    if (ios9)
    {
        return [UIFont monospacedDigitSystemFontOfSize:fontSize weight:UIFontWeightMedium];
    }
    else
    {
        return [UIFont boldSystemFontOfSize:fontSize];
    }
}

@end
