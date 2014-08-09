//
//  CardImageCell.m
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardImageCell.h"
#import "ImageCache.h"
#import "CardCounter.h"
#import "CardDetailView.h"

@implementation CardImageCell

-(void) awakeFromNib
{
    // remove all constraints IB has generated
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self removeConstraints:self.constraints];
    [self.detailView removeConstraints:self.detailView.constraints];
    
    NSDictionary* views = @{
                            @"image1": self.image1,
                            @"image2": self.image2,
                            @"image3": self.image3,
                            @"activity": self.activityIndicator,
                            @"toggle": self.toggleButton,
                            @"label": self.copiesLabel,
                            @"details": self.detailView,
                            };
    
    NSArray* constraints = @[
                             @"H:|[image1]-10-|",
                             @"H:|-5-[image2]-5-|",
                             @"H:|-10-[image3]|",
                             @"H:|[label]|",
                             @"H:[toggle(28)]",
                             @"H:|[details]|",
                             @"V:|[image1(image3)]",
                             @"V:|-5-[image2(image3)]",
                             @"V:|-10-[image3][label(20)]|",
                             @"V:|[details]-20-|",
                             @"V:[toggle(34)]",
                            ];
    
    // see http://stackoverflow.com/questions/12873372/centering-a-view-in-its-superview-using-visual-format-language
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
                                                        toItem:self.image2
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1 constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.toggleButton
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.image3
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1 constant:0]];
    
    for (NSString* c in constraints)
    {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:c options:0 metrics:nil views:views]];
    }
    
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
    
    // add parallax effect to cell
    [self addMotionEffect:[self effectX:10]];
    [self addMotionEffect:[self effectY:10]];
    
    // rounded corners for images
    self.image1.layer.masksToBounds = YES;
    self.image1.layer.cornerRadius = 10;
    self.image2.layer.masksToBounds = YES;
    self.image2.layer.cornerRadius = 10;
    self.image3.layer.masksToBounds = YES;
    self.image3.layer.cornerRadius = 10;
}

-(void) setCc:(CardCounter *)cc
{
    self->_cc = cc;
    self.toggleButton.hidden = self.cc.card.altCard == nil;
    self.toggleButton.layer.masksToBounds = YES;
    self.toggleButton.layer.cornerRadius = 3;
    
    [self setImageStack:self.image1.image];
    
    [self.toggleButton setImage:[ImageCache altArtIcon:self.cc.showAltArt] forState:UIControlStateNormal];
}

-(void) setImageStack:(UIImage*)img
{
    self.image1.image = img;
    self.image2.image = self.cc.count > 1 ? img : nil;
    self.image3.image = self.cc.count > 2 ? img : nil;
    
    NSUInteger max3 = MIN(self.cc.count, 3);
    NSUInteger c = MAX(max3-1, 0);
    self.image1.layer.opacity = 1.0 - (c * 0.2);
    c = MAX(c-1, 0);
    self.image2.layer.opacity = 1.0 - (c * 0.2);
    c = MAX(c-1, 0);
    self.image3.layer.opacity = 1.0 - (c * 0.2);
}

-(void) toggleImage:(id)sender
{
    self.cc.showAltArt = !self.cc.showAltArt;
    [self.toggleButton setImage:[ImageCache altArtIcon:self.cc.showAltArt] forState:UIControlStateNormal];
    [self loadImage];
}

-(void) loadImage
{
    Card* card = self.cc.showAltArt ? self.cc.card.altCard : self.cc.card;
    [self loadImage:card];
}

-(void) loadImage:(Card*)card
{
    [self.activityIndicator startAnimating];
    [[ImageCache sharedInstance] getImageFor:card
                                     completion:^(Card* card, UIImage* img, BOOL placeholder) {
                                         [self.activityIndicator stopAnimating];
                                         if ([self.cc.card.name isEqual:card.name])
                                         {
                                             [self setImageStack:img];
                                         
                                             self.detailView.hidden = !placeholder;
                                             if (placeholder)
                                             {
                                                 [CardDetailView setupDetailViewFromCell:self card:self.cc.card];
                                             }
                                         }
                                     }];
}

#pragma mark parallax helpers

-(UIInterpolatingMotionEffect*) effectX:(float)depth
{
    UIInterpolatingMotionEffect* effect = [[UIInterpolatingMotionEffect alloc]
                                           initWithKeyPath:@"center.x"
                                           type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effect.minimumRelativeValue = @(-depth);
    effect.maximumRelativeValue = @(depth);
    return effect;
}

-(UIInterpolatingMotionEffect*) effectY:(float)depth
{
    UIInterpolatingMotionEffect* effect = [[UIInterpolatingMotionEffect alloc]
                                           initWithKeyPath:@"center.y"
                                           type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    effect.minimumRelativeValue = @(-depth);
    effect.maximumRelativeValue = @(depth);
    return effect;
}

@end
