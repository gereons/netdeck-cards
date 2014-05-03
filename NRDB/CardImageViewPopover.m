//
//  CardImageViewPopover.m
//  NRDB
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardImageViewPopover.h"
#import "Card.h"
#import "ImageCache.h"
#import "CardDetailView.h"
#import <EXTScope.h>

@interface CardImageViewPopover ()

@property Card* card;
@property BOOL showAlt;

@end

@implementation CardImageViewPopover

static UIPopoverController* popover;

+(void)showForCard:(Card *)card fromRect:(CGRect)rect inView:(UIView*)view
{
    CardImageViewPopover* cardImageView = [[CardImageViewPopover alloc] initWithCard:card];
    
    popover = [[UIPopoverController alloc] initWithContentViewController:cardImageView];
    popover.popoverContentSize = CGSizeMake(300, 418);
    popover.backgroundColor = [UIColor whiteColor];
    popover.delegate = cardImageView;
    
    [popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight animated:NO];
}

+(void) dismiss
{
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        popover = nil;
    }
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    [popoverController dismissPopoverAnimated:NO];
    return YES;
}

- (id)initWithCard:(Card*)card
{
    self = [super initWithNibName:@"CardImageView" bundle:nil];
    if (self)
    {
        self.card = card;
        self.showAlt = NO;
        self.detailView.hidden = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer* imgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imgTap:)];
    imgTap.numberOfTapsRequired = 1;
    [self.imageView addGestureRecognizer:imgTap];
    
    if (self.card.altCard == nil)
    {
        self.toggleButton.hidden = YES;
    }
    
    [self.toggleButton setImage:[ImageCache altArtIcon:self.showAlt] forState:UIControlStateNormal];
    [self loadCardImage:self.card];
}

-(void) imgTap:(UITapGestureRecognizer*)sender
{
    if (UIGestureRecognizerStateEnded == sender.state)
    {
        [CardImageViewPopover dismiss];
    }
}

-(void) toggleImage:(id)sender
{
    self.showAlt = !self.showAlt;
    Card* altCard = self.card.altCard;
    
    if (altCard)
    {
        Card* card = self.showAlt ? altCard : self.card;
        [self loadCardImage:card];
        [self.toggleButton setImage:[ImageCache altArtIcon:self.showAlt] forState:UIControlStateNormal];
    }
}

-(void) loadCardImage:(Card*)card
{
    [self.activityIndicator startAnimating];
    @weakify(self);
    [[ImageCache sharedInstance] getImageFor:card
                                     completion:^(Card* card, UIImage* image, BOOL placeholder) {
                                         @strongify(self);
                                         [self.activityIndicator stopAnimating];
                                         self.imageView.image = image;
                                         
                                         if (placeholder)
                                         {
                                             [CardDetailView setupDetailViewFromPopover:self card:self.card];
                                         }
                                     }];

}

@end
