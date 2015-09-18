//
//  SmallPipsView.m
//  Net Deck
//
//  Created by Gereon Steffens on 15.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "SmallPipsView.h"

@interface SmallPipsView()
@property NSArray* views;
@end

@implementation SmallPipsView

+(SmallPipsView*) createWithFrame:(CGRect)rect
{
    SmallPipsView* pips = [[[NSBundle mainBundle] loadNibNamed:@"SmallPipsView" owner:self options:nil] objectAtIndex:0];
    pips.frame = rect;
    return pips;
}

-(void)awakeFromNib
{
    self.views = @[ self.pipNW, self.pipNE, self.pipCenter, self.pipSW, self.pipSE ];
    for (UIView* v in self.views)
    {
        v.layer.cornerRadius = 2;
        [self hideAll];
    }
}

-(void) hideAll
{
    for (UIView* v in self.views)
    {
        v.hidden = YES;
    }
}

-(void) setColor:(UIColor*)color
{
    for (UIView* v in self.views)
    {
        v.backgroundColor = color;
    }
}

-(void) setValue:(int)value
{
    NSArray* show;
    switch (value) {
        case 1:
            show = @[ self.pipCenter ];
            break;
        case 2:
            show = @[ self.pipNE, self.pipSW ];
            break;
        case 3:
            show = @[ self.pipNW, self.pipSE, self.pipCenter ];
            break;
        case 4:
            show = @[ self.pipNW, self.pipSE, self.pipSW, self.pipNE ];
            break;
        case 5:
            show = self.views;
            break;
    }
    [self hideAll];
    for (UIView* v in show)
    {
        v.hidden = NO;
    }
}

@end
