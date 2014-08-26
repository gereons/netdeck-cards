//
//  IdentityCardView.m
//  NRDB
//
//  Created by Gereon Steffens on 26.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "IdentityCardView.h"
#import "ImageCache.h"
#import "Card.h"
#import <EXTScope.h>

@implementation IdentityCardView

-(void) awakeFromNib
{
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
    self.nameLabel.text = nil;
    [self.selectButton setTitle:l10n(@"Select") forState:UIControlStateNormal];
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
             
             self.imageView.image = [ImageCache croppedImage:img forCard:card];
             self.nameLabel.text = placeholder ? card.name : nil;
         }
     }];
}

@end
