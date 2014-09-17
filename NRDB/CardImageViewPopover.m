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

#define IMAGE_WIDTH     300
#define IMAGE_HEIGHT    418
#define POPOVER_MARGIN  40 // 20px status bar + 10px top + 10px bottom
#define SCREEN_HEIGHT   768

@interface CardImageViewPopover ()

@property Card* card;
@property BOOL showAlt;

@end

static UIPopoverController* popover;
static BOOL keyboardVisible = NO;
static CGFloat popoverScale = 1.0;

@implementation CardImageViewPopover

#pragma mark keyboard monitor

+(void)monitorKeyboard
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [nc addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

+(void) showKeyboard:(NSNotification*)notification
{
    keyboardVisible = YES;
    NSValue* value = notification.userInfo [UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = IS_IOS7 ? value.CGRectValue.size.width : value.CGRectValue.size.height;
    popoverScale = (SCREEN_HEIGHT - keyboardHeight - POPOVER_MARGIN) / IMAGE_HEIGHT;
}

+(void) hideKeyboard:(NSNotification*)sender
{
    keyboardVisible = NO;
    popoverScale = 1.0;
    
    if (popover)
    {
        CardImageViewPopover* ci = (CardImageViewPopover*)popover.contentViewController;
        ci.view.transform = CGAffineTransformIdentity;
        popover.popoverContentSize = CGSizeMake(IMAGE_WIDTH, IMAGE_HEIGHT);
    }
}

#pragma mark show/dismiss

+(void)showForCard:(Card *)card fromRect:(CGRect)rect inView:(UIView*)view
{
    CardImageViewPopover* cardImageView = [[CardImageViewPopover alloc] initWithCard:card];
    
    popover = [[UIPopoverController alloc] initWithContentViewController:cardImageView];
    
    popover.popoverContentSize = CGSizeMake((int)(IMAGE_WIDTH*popoverScale), (int)(IMAGE_HEIGHT*popoverScale));
    popover.backgroundColor = [UIColor whiteColor];
    popover.delegate = cardImageView;
    
    [popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight animated:NO];
}

+(BOOL) dismiss
{
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        popover = nil;
        return YES;
    }
    return NO;
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
        
        if (keyboardVisible)
        {
            self.view.transform = CGAffineTransformMakeScale(popoverScale, popoverScale);
        }
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
    
    // rounded corners for toggle button
    self.toggleButton.layer.masksToBounds = YES;
    self.toggleButton.layer.cornerRadius = 3;
    
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
                                         
                                         self.detailView.hidden = !placeholder;
                                         if (placeholder)
                                         {
                                             [CardDetailView setupDetailViewFromPopover:self card:self.card];
                                         }
                                     }];

}

@end
