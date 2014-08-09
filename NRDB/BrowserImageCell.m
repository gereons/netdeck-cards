//
//  BrowserImageCell.m
//  NRDB
//
//  Created by Gereon Steffens on 09.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "BrowserImageCell.h"
#import "Card.h"
#import "ImageCache.h"

@interface BrowserImageCell()
@property BOOL showAltArt;
@end

@implementation BrowserImageCell

-(void) awakeFromNib
{
    // rounded corners for images
    self.image.layer.masksToBounds = YES;
    self.image.layer.cornerRadius = 10;
    self.showAltArt = NO;
    
    self.toggleButton.hidden = YES;
    
    // remove all constraints IB has generated
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self removeConstraints:self.constraints];
    
    NSDictionary* views = @{
        @"image": self.image,
        @"toggle": self.toggleButton
    };
    NSArray* constraints = @[
                             @"H:|[image]|",
                             @"H:[toggle]|",
                             @"V:|[image]|",
                             ];

    for (NSString* c in constraints)
    {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:c options:0 metrics:nil views:views]];
    }
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1 constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1 constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.toggleButton
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1 constant:0]];
}

-(void) prepareForReuse
{
    self.showAltArt = NO;
}

-(void) setCard:(Card *)card
{
    self->_card = card;
    self.toggleButton.hidden = card.altCard == nil;
    [self.toggleButton setImage:[ImageCache altArtIcon:self.showAltArt] forState:UIControlStateNormal];
    
    [self loadImageFor:card];
}

-(void) toggleImage:(id)sender
{
    self.showAltArt = !self.showAltArt;
    [self.toggleButton setImage:[ImageCache altArtIcon:self.showAltArt] forState:UIControlStateNormal];
    Card* card = self.showAltArt ? self.card.altCard : self.card;
    
    [self loadImageFor:card];
}

-(void) loadImageFor:(Card *)card
{
    if (self.card != card)
    {
        self.image.image = nil;
    }
    
    [self.activityIndicator startAnimating];
    [[ImageCache sharedInstance] getImageFor:card
                                  completion:^(Card* card, UIImage* img, BOOL placeholder) {
                                      [self.activityIndicator stopAnimating];
                                      if ([self.card.name isEqual:card.name])
                                      {
                                          self.image.image = img;
                                      }
                                  }];
}

@end
