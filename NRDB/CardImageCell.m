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

@implementation CardImageCell

/*
 TODO: draw stack border around card
 see https://stackoverflow.com/questions/6434925/how-to-draw-uibezierpaths
 see http://ronnqvi.st/thinking-like-a-bzier-path/
 */

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // self.showAltArt = NO;
    }
    return self;
}

-(void) toggleImage
{
    self.cc.showAltArt = !self.cc.showAltArt;
    
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
                                     success:^(Card* card, UIImage* img) {
                                         [self.activityIndicator stopAnimating];
                                         if ([self.cc.card.name isEqual:card.name])
                                         {
                                             self.imageView.image = img;
                                         }
                                         else
                                         {
                                             NSLog(@"got img %@ for %@", card.name, self.cc.card.name);
                                         }
                                     }
                                     failure:^(Card* card, UIImage* placeholder) {
                                         [self.activityIndicator stopAnimating];
                                         if ([self.cc.card.name isEqual:card.name])
                                         {
                                             self.imageView.image = placeholder;
                                         }
                                     }];
}

@end
