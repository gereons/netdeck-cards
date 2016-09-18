//
//  CardImageCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardImageCell.h"
#import "CardDetailView.h"

@implementation CardImageCell

-(void) awakeFromNib
{
    [super awakeFromNib];

    // rounded corners for images
    self.image1.layer.masksToBounds = YES;
    self.image1.layer.cornerRadius = 10;

    self.image2.layer.masksToBounds = YES;
    self.image2.layer.cornerRadius = 10;

    self.image3.layer.masksToBounds = YES;
    self.image3.layer.cornerRadius = 10;
}

-(void) prepareForReuse
{
    self.image1.image = nil;
    self.image2.image = nil;
    self.image3.image = nil;
    self.detailView.hidden = YES;
}

-(void) setCc:(CardCounter *)cc
{
    self->_cc = cc;
    [self setImageStack:self.image1.image];
}

-(void) setImageStack:(UIImage*)img
{
    self.image1.image = img;
    self.image2.image = self.cc.count > 1 ? img : nil;
    self.image3.image = self.cc.count > 2 ? img : nil;
    
    NSUInteger count = self.cc ? self.cc.count : 1;
    NSUInteger max3 = MIN(count, 3);
    NSUInteger c = MAX(max3-1, 0);
    self.image1.layer.opacity = 1.0 - (c * 0.2);
    c = MAX(c-1, 0);
    self.image2.layer.opacity = 1.0 - (c * 0.2);
    c = MAX(c-1, 0);
    self.image3.layer.opacity = 1.0 - (c * 0.2);
}

-(void) loadImage
{
    Card* card = self.cc.card;
    [self.activityIndicator startAnimating];
    
    [self loadImage:card];
}

-(void) loadImage:(Card*)card
{
    if (card == nil) {
        return;
    }
    [[ImageCache sharedInstance] getImageFor:card
                                  completion:^(Card* card, UIImage* img, BOOL placeholder) {
                                      if ([self.cc.card.code isEqual:card.code])
                                      {
                                          [self.activityIndicator stopAnimating];
                                          [self setImageStack:img];
                                          
                                          self.detailView.hidden = !placeholder;
                                          if (placeholder)
                                          {
                                              [CardDetailView setupDetailViewFromCell:self card:self.cc.card];
                                          }
                                      }
                                      else
                                      {
                                          [self loadImage:self.cc.card];
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
