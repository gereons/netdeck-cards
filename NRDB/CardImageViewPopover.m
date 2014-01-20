//
//  CardImageViewPopover.m
//  NRDB
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CardImageViewPopover.h"
#import "Card.h"
#import "ImageCache.h"

@interface CardImageViewPopover ()

@property Card* card;

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
    
    [self.activityIndicator startAnimating];
    [[ImageCache sharedInstance] getImageFor:self.card
                                     success:^(Card* card, UIImage* image) {
                                         [self.activityIndicator stopAnimating];
                                         self.imageView.image = image;
                                     }
                                     failure:^(Card* card, NSInteger statusCode){
                                        [self.activityIndicator stopAnimating];
                                     }];
}

-(void) imgTap:(UITapGestureRecognizer*)sender
{
    if (UIGestureRecognizerStateEnded == sender.state)
    {
        [CardImageViewPopover dismiss];
    }
}

@end
