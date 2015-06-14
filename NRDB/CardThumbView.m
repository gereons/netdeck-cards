//
//  CardThumbView.m
//  NRDB
//
//  Created by Gereon Steffens on 24.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//
//  used in draw simulator & identity picker
//

#import "CardThumbView.h"
#import "Card.h"
#import "ImageCache.h"

@implementation CardThumbView

-(void) awakeFromNib
{
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
    self.nameLabel.text = nil;
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
             
             self.imageView.image = [ImageCache croppedImage:img forCard:card];
             self.nameLabel.text = placeholder ? card.name : nil;
         }
         else
         {
             [self loadImageFor:self.card];
         }
     }];
}
@end
