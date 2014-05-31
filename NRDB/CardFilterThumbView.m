//
//  CardFilterThumbView.m
//  NRDB
//
//  Created by Gereon Steffens on 31.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardFilterThumbView.h"
#import "Card.h"
#import "ImageCache.h"
#import <EXTScope.h>

@implementation CardFilterThumbView

-(void) awakeFromNib
{
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
    self.nameLabel.text = nil;
    self.countLabel.text = nil;
}

-(void) setCard:(Card *)card
{
    self.imageView.image = nil;
    self->_card = card;
    
    [self.activityIndicator startAnimating];
    @weakify(self);
    [[ImageCache sharedInstance] getImageFor:card completion:^(Card* card, UIImage* img, BOOL placeholder)
     {
         @strongify(self);
         if ([self.card.code isEqual:card.code])
         {
             [self.activityIndicator stopAnimating];
             CGRect rect = CGRectMake(10, card.cropY, 280, 209);
             CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], rect);
             UIImage *cropped = [UIImage imageWithCGImage:imageRef];
             CGImageRelease(imageRef);
             
             self.imageView.image = cropped;
             self.nameLabel.text = placeholder ? card.name : nil;
         }
     }];
}

@end
