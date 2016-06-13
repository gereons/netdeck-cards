//
//  CardFilterThumbView.m
//  Net Deck
//
//  Created by Gereon Steffens on 31.05.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
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

-(void) setCard:(Card *)card
{
    self.imageView.image = nil;
    self->_card = card;
    
    [self.activityIndicator startAnimating];
    
    [self loadImageFor:card];
}

-(void) loadImageFor:(Card*)card
{
    if (card == nil) {
        return;
    }
    [[ImageCache sharedInstance] getImageFor:card completion:^(Card* card, UIImage* img, BOOL placeholder)
     {
         if ([self.card.code isEqual:card.code])
         {
             [self.activityIndicator stopAnimating];
             
             self.imageView.image = [[ImageCache sharedInstance] croppedImage:img forCard:card];
             self.nameLabel.text = placeholder ? card.name : nil;
         }
         else
         {
             [self loadImageFor:self.card];
         }
     }];
}

-(void) prepareForReuse
{
    self.nameLabel.text = nil;
    self.countLabel.text = nil;
    self.imageView.image = nil;
}

@end
