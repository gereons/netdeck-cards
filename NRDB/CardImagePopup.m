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
    popover.popoverContentSize = cardImageView.view.frame.size;
    popover.backgroundColor = [UIColor clearColor];
    
    [popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown animated:NO];
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
    self.nameLabel.text = self.cc.card.name;
}

-(void) copiesChanged:(id)sender
{
    int count = self.copiesStepper.value;
    BOOL delete = count == 0;
    
    self.cc.count = count;
    if (delete)
    {
        [CardImagePopup dismiss];
    }
    else
    {
        self.copiesLabel.text = [NSString stringWithFormat:@"×%d", self.cc.count];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
}

@end
