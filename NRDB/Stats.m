//
//  Stats.m
//  NRDB
//
//  Created by Gereon Steffens on 16.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Stats.h"

@implementation Stats

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    // 1626c4
    UIColor* base = [UIColor colorWithRed:0x16/256.0 green:0x26/256.0 blue:0xc4/256.0 alpha:1];
    CGFloat hue, brightness, saturation, alpha;
    [base getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    hue *= 360.0;
    float step = 360.0 / self.tableData.sections.count;
    for (int i=0; i<index; ++i)
    {
        hue += step;
        if (hue > 360.0) hue -= 360.0;
    }
    
    UIColor* col = [UIColor colorWithHue:hue/360.0 saturation:saturation brightness:brightness alpha:alpha];
    
    return [CPTFill fillWithColor:[CPTColor colorWithCGColor:col.CGColor]];
}

@end
