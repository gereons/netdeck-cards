//
//  CardImageCell.m
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardImageCell.h"
#import "ImageCache.h"
#import "Card.h"

@interface CardImageCell()
@property BOOL showAltArt;
@end

@implementation CardImageCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.showAltArt = NO;
    }
    return self;
}

-(void) toggleImage
{
    self.showAltArt = !self.showAltArt;
    
    Card* card = self.showAltArt ? self.card.altCard : self.card;
    [self loadImage:card];
}

-(void) loadImage:(Card*)card
{
    [self.activityIndicator startAnimating];
    [[ImageCache sharedInstance] getImageFor:card
                                     success:^(Card* card, UIImage* img) {
                                         [self.activityIndicator stopAnimating];
                                         if ([self.card.name isEqual:card.name])
                                         {
                                             self.imageView.image = img;
                                         }
                                         else
                                         {
                                             NSLog(@"got img %@ for %@", card.name, self.card.name);
                                         }
                                     }
                                     failure:^(Card* card, UIImage* placeholder) {
                                         [self.activityIndicator stopAnimating];
                                         if ([self.card.name isEqual:card.name])
                                         {
                                             self.imageView.image = placeholder;
                                         }
                                     }];
}

@end
