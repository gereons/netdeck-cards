//
//  CardThumbView.m
//  NRDB
//
//  Created by Gereon Steffens on 24.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardThumbView.h"

@implementation CardThumbView

-(void) awakeFromNib
{
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
    self.nameLabel.text = nil;
}

@end
