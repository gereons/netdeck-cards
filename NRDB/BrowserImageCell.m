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
#import "CardDetailView.h"

static NSMutableSet* altArt;

@interface BrowserImageCell()
@property BOOL showAltArt;
@end

@implementation BrowserImageCell

+(void) initialize
{
    altArt = [NSMutableSet set];
}

-(void) awakeFromNib
{
    // rounded corners for images
    self.image.layer.masksToBounds = YES;
    self.image.layer.cornerRadius = 10;
    self.showAltArt = NO;
    
    // rounded corners for toggle button
    self.toggleButton.layer.masksToBounds = YES;
    self.toggleButton.layer.cornerRadius = 3;
    
    self.toggleButton.hidden = YES;
    
    // remove all constraints IB has generated
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self removeConstraints:self.constraints];
    
    NSDictionary* views = @{
        @"image": self.image,
        @"toggle": self.toggleButton,
        @"details": self.detailView
    };
    NSArray* constraints = @[
                             @"H:|[image]|",
                             @"H:[toggle(28)]|",
                             @"V:|[image]|",
                             @"H:|[details]|",
                             @"V:|[details]|",
                             @"V:[toggle(34)]",
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
    
    [self.detailView removeConstraints:self.detailView.constraints];
    views = @{ @"name": self.cardName,
               @"type": self.cardType,
               @"text": self.cardText,
               @"label1": self.label1,
               @"label2": self.label2,
               @"label3": self.label3,
               @"icon1": self.icon1,
               @"icon2": self.icon2,
               @"icon3": self.icon3,
               };
    
    constraints = @[
                    @"H:|-[name]-|",
                    @"H:|-[type]-|",
                    @"H:|-[text]-|",
                    @"H:|-[label1][icon1]",
                    @"H:[label3][icon3]-|",
                    @"V:|-[name]-[label1]-[type]-[text]-|",
                    @"V:|-[name]-[label2]",
                    @"V:|-[name]-[label3]",
                    @"V:|-[name]-[icon1]",
                    @"V:|-[name]-[icon2]",
                    @"V:|-[name]-[icon3]",
                    ];
    for (NSString* c in constraints)
    {
        [self.detailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:c options:0 metrics:nil views:views]];
    }
    
    [self.detailView addConstraint:[NSLayoutConstraint constraintWithItem:self.label2
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.detailView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.f constant:-7.f]];
    [self.detailView addConstraint:[NSLayoutConstraint constraintWithItem:self.icon2
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.detailView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.f constant:8.f]];
}

-(void) prepareForReuse
{
    self.image.image = nil;
}

-(void) setCard:(Card *)card
{
    self->_card = card;
    self.toggleButton.hidden = card.altCard == nil;
    self.showAltArt = NO;
    
    if (card.altCard && [altArt containsObject:card.code])
    {
        card = card.altCard;
        self.showAltArt = YES;
    }
    
    [self.toggleButton setImage:[ImageCache altArtIcon:self.showAltArt] forState:UIControlStateNormal];
    [self loadImageFor:card];
}

-(void) toggleImage:(id)sender
{
    self.showAltArt = !self.showAltArt;
    if (self.showAltArt)
    {
        [altArt addObject:self.card.code];
    }
    else
    {
        [altArt removeObject:self.card.code];
    }
    
    [self.toggleButton setImage:[ImageCache altArtIcon:self.showAltArt] forState:UIControlStateNormal];
    Card* card = self.card;
    if (self.showAltArt && self.card.altCard)
    {
        card = self.card.altCard;
    }
    
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
                                          
                                          self.detailView.hidden = !placeholder;
                                          if (placeholder)
                                          {
                                              [CardDetailView setupDetailViewFromBrowser:self card:card];
                                          }
                                      }
                                  }];
}

@end
