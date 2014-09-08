//
//  NROutlineLabel.m
//  NRDB
//
//  Created by Gereon Steffens on 24.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "NROutlineLabel.h"

@implementation NROutlineLabel

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self awakeFromNib];
    }
    return self;
}

- (void) awakeFromNib
{
    self.outlineWidth = 2;
    self.outlineColor = [UIColor whiteColor];
}

- (void)drawTextInRect:(CGRect)rect {
    
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, self.outlineWidth);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = self.outlineColor;
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
}

@end
