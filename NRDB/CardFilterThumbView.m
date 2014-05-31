//
//  CardFilterThumbView.m
//  NRDB
//
//  Created by Gereon Steffens on 31.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardFilterThumbView.h"

@implementation CardFilterThumbView

-(void) awakeFromNib
{
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
    self.nameLabel.text = nil;
    self.countLabel.text = nil;
}

@end
