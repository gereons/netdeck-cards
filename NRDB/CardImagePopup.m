//
//  CardImagePopup.m
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardImagePopup.h"
#import "CardCounter.h"
#import "Notifications.h"

@interface CardImagePopup ()

@property CardCounter* cc;

@end

@implementation CardImagePopup

static UIPopoverController* popover;

+(void)showForCard:(CardCounter *)cc fromRect:(CGRect)rect inView:(UIView*)view
{
    CardImagePopup* cardImageView = [[CardImagePopup alloc] initWithCard:cc];
    
    popover = [[UIPopoverController alloc] initWithContentViewController:cardImageView];
    popover.popoverContentSize = cardImageView.view.frame.size; // CGSizeMake(134, 136);
    popover.backgroundColor = [UIColor clearColor];
    
    [popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionUp|UIPopoverArrowDirectionUp animated:NO];
}

+(void) dismiss
{
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        popover = nil;
    }
}

- (id)initWithCard:(CardCounter*)cc
{
    self = [super initWithNibName:@"CardImagePopup" bundle:nil];
    if (self)
    {
        self.cc = cc;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.copiesStepper.value = self.cc.count;
    self.copiesLabel.text = [NSString stringWithFormat:@"×%d", self.cc.count];
}

-(void) copiesChanged:(id)sender
{
    int count = self.copiesStepper.value;
    if (count == 0)
    {
        [self deleteCard:sender];
    }
    else
    {
        self.cc.count = self.copiesStepper.value;
        self.copiesLabel.text = [NSString stringWithFormat:@"×%d", self.cc.count];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
    }
}

-(void) deleteCard:(id)sender
{
    self.cc.count = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
    [CardImagePopup dismiss];
}

@end
