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
    
    [self loadCardImage:self.card];
}

-(void) imgTap:(UITapGestureRecognizer*)sender
{
    if (UIGestureRecognizerStateEnded == sender.state)
    {
        self.showAlt = !self.showAlt;
        Card* altCard = self.card.altCard;
        
        if (altCard)
        {
            Card* card = self.showAlt ? altCard : self.card;
            [self loadCardImage:card];
        }
    }
}

-(void) loadCardImage:(Card*)card
{
    [self.activityIndicator startAnimating];
    [[ImageCache sharedInstance] getImageFor:card
                                     success:^(Card* card, UIImage* image) {
                                         [self.activityIndicator stopAnimating];
                                         self.imageView.image = image;
                                     }
                                     failure:^(Card* card, UIImage* placeholder) {
                                         [self.activityIndicator stopAnimating];
                                         self.imageView.image = placeholder;
                                     }];

}

@end
