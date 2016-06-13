//
//  CardImageViewPopover.m
//  Net Deck
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardImageViewPopover.h"
#import "CardDetailView.h"

#define POPOVER_MARGIN  40 // 20px status bar + 10px top + 10px bottom
#define IPAD_SCREEN_HEIGHT   768

@interface CardImageViewPopover ()

@property Card* card;
@property BOOL showAlt;

@end

static CardImageViewPopover* popover;

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
    CGFloat keyboardHeight = value.CGRectValue.size.height;
    popoverScale = (IPAD_SCREEN_HEIGHT - keyboardHeight - POPOVER_MARGIN) / ImageCache.IMAGE_HEIGHT;
    popoverScale = MIN(1.0, popoverScale);
}

+(void) hideKeyboard:(NSNotification*)sender
{
    keyboardVisible = NO;
    popoverScale = 1.0;
    
    if (popover)
    {
        popover.view.transform = CGAffineTransformIdentity;
        popover.preferredContentSize = CGSizeMake(ImageCache.IMAGE_WIDTH, ImageCache.IMAGE_HEIGHT);
    }
}

#pragma mark show/dismiss

+(void)showForCard:(Card *)card fromRect:(CGRect)rect inViewController:(UIViewController *)vc subView:(UIView *)view
{
    if (card == nil || vc == nil)
    {
        return;
    }
    
    NSAssert(popover == nil, @"previous popover still visible?");
    popover = [[CardImageViewPopover alloc] initWithCard:card];
    
    popover.modalPresentationStyle = UIModalPresentationPopover;
    popover.popoverPresentationController.sourceRect = rect;
    popover.popoverPresentationController.sourceView = view;
    popover.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight;
    popover.popoverPresentationController.delegate = popover;
    popover.preferredContentSize = CGSizeMake((int)(ImageCache.IMAGE_WIDTH*popoverScale), (int)(ImageCache.IMAGE_HEIGHT*popoverScale));
    
    [vc presentViewController:popover animated:NO completion:nil];
}

+(BOOL) dismiss
{
    if (popover)
    {
        [popover dismissViewControllerAnimated:NO completion:nil];
        popover = nil;
        return YES;
    }
    return NO;
}

-(void) popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    popover = nil;
}

- (id)initWithCard:(Card*)card
{
    self = [super initWithNibName:@"CardImageView" bundle:nil];
    if (self)
    {
        self.card = card;
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
    
    [self loadCardImage];
}

-(void) imgTap:(UITapGestureRecognizer*)sender
{
    if (UIGestureRecognizerStateEnded == sender.state)
    {
        [CardImageViewPopover dismiss];
    }
}

-(void) loadCardImage
{
    [self.activityIndicator startAnimating];
    [self loadCardImage:self.card];
}

-(void) loadCardImage:(Card*)card
{
    if (card == nil) {
        return;
    }
    [[ImageCache sharedInstance] getImageFor:card
                                     completion:^(Card* card, UIImage* image, BOOL placeholder) {
                                         if ([card.code isEqualToString:self.card.code])
                                         {
                                             [self.activityIndicator stopAnimating];
                                             self.imageView.image = image;
                                             
                                             self.detailView.hidden = !placeholder;
                                             if (placeholder)
                                             {
                                                 [CardDetailView setupDetailViewFromPopover:self card:self.card];
                                             }
                                         }
                                         else
                                         {
                                             [self loadCardImage:self.card];
                                         }
                                     }];

}

@end
