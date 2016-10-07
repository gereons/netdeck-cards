//
//  BrowserImageCell.m
//  Net Deck
//
//  Created by Gereon Steffens on 09.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "BrowserImageCell.h"
#import "CardDetailView.h"

@implementation BrowserImageCell

-(void) awakeFromNib
{
    [super awakeFromNib];
    
    // rounded corners for images
    self.image.layer.masksToBounds = YES;
    self.image.layer.cornerRadius = 10;
}

-(void) prepareForReuse
{
    self.image.image = nil;
    self->_card = nil;
    self.detailView.hidden = YES;
}

-(void) setCard:(Card *)card
{
    self->_card = card;
    [self.activityIndicator startAnimating];
    
    [self loadImageFor:card];
}

-(void) loadImageFor:(Card *)card
{
    if (card == nil) {
        return;
    }
    
    [[ImageCache sharedInstance] getImageFor:card completion:^(Card* card, UIImage* img, BOOL placeholder) {
        if ([self.card.code isEqual:card.code])
        {
              [self.activityIndicator stopAnimating];
              self.image.image = img;
              
              self.detailView.hidden = !placeholder;
              if (placeholder)
              {
                  [CardDetailView setupDetailViewFromBrowser:self card:card];
              }
        }
        else
        {
            [self loadImageFor:self.card];
        }
    }];
}

@end
