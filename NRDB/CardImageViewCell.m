//
//  CardImageViewCell.m
//  NRDB
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "CardImageViewCell.h"
#import "Card.h"
#import "ImageCache.h"

@implementation CardImageViewCell

-(void) awakeFromNib
{
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
}

-(void) setCard:(Card *)card
{
    self.imageView.image = nil;
    self->_card = card;
    
    [self.activityIndicator startAnimating];
    
    [self loadImageFor:card];
}

-(void) loadImageFor:(Card*)card
{
    [[ImageCache sharedInstance] getImageFor:card completion:^(Card* card, UIImage* img, BOOL placeholder)
     {
         if ([self.card.code isEqual:card.code])
         {
             [self.activityIndicator stopAnimating];
             self.imageView.image = img;
         }
         else
         {
             [self loadImageFor:self.card];
         }
     }];
}


@end
