//
//  CardImageViewCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardImageViewCell.h"
#import "CardDetailView.h"

@interface CardImageViewCell()

@property (nonatomic)Card* card;
@property NSInteger count;

@end

@implementation CardImageViewCell

-(void) awakeFromNib
{
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
    self.countLabel.text = @"";
}

-(void) setCard:(Card *)card
{
    [self setCard:card andCount:-1];
}

-(void) setCard:(Card *)card andCount:(NSInteger)count
{
    if (card.type == NRCardTypeIdentity)
    {
        count = 0;
    }

    self.imageView.image = nil;
    self->_card = card;
    self->_count = count;
    
    [self.activityIndicator startAnimating];
    
    [self loadImageFor:card andCount:count];
}

-(void) loadImageFor:(Card*)card andCount:(NSInteger)count
{
    [[ImageCache sharedInstance] getImageFor:card completion:^(Card* card, UIImage* img, BOOL placeholder)
     {
         if ([self.card.code isEqual:card.code])
         {
             [self.activityIndicator stopAnimating];
             self.imageView.image = img;
             
             if (self.showAsDifferences) {
                 self.countLabel.text = [NSString stringWithFormat:@"%+ld", (long)count];
             } else {
                 if (count > 0) {
                     self.countLabel.text = [NSString stringWithFormat:@"%ld×", (long)count];
                 } else {
                     self.countLabel.text = @"";
                 }
             }
             
             self.imageView.hidden = NO;
             self.detailView.hidden = !placeholder;
             if (placeholder)
             {
                 [CardDetailView setupDetailViewFromIphone:self card:card];
             }
         }
         else
         {
             [self loadImageFor:self.card andCount:self.count];
         }
     }];
}


@end
