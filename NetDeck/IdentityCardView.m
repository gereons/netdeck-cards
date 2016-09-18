//
//  IdentityCardView.m
//  Net Deck
//
//  Created by Gereon Steffens on 26.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "IdentityCardView.h"

@implementation IdentityCardView

-(void) awakeFromNib
{
    [super awakeFromNib];
    
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

@end
