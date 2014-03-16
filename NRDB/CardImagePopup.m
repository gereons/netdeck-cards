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
#import "SettingsKeys.h"
#import "CardImageCell.h"

@interface CardImagePopup ()

@property CardCounter* cc;

@end

@implementation CardImagePopup

static UIPopoverController* popover;

+(CardImagePopup*) showForCard:(CardCounter *)cc fromRect:(CGRect)rect inView:(UIView*)view direction:(UIPopoverArrowDirection)direction
{
    CardImagePopup* cip = [[CardImagePopup alloc] initWithCard:cc];
    
    popover = [[UIPopoverController alloc] initWithContentViewController:cip];
    popover.popoverContentSize = cip.view.frame.size;
    popover.backgroundColor = [UIColor whiteColor];
    
    [popover presentPopoverFromRect:rect inView:view permittedArrowDirections:direction animated:NO];
    return cip;
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
    self.copiesStepper.maximumValue = self.cc.card.maxCopies;
    self.copiesLabel.text = [NSString stringWithFormat:@"×%d", self.cc.count];
    self.nameLabel.text = self.cc.card.name;
    
    // auto-scaling of fonts does not work in multiline labels. DIY :(
    int maxDesiredFontSize = 14;
    int minFontSize = 8;
    CGFloat labelWidth = self.nameLabel.frame.size.width;
    CGFloat labelRequiredHeight = self.nameLabel.frame.size.height;
    
    UIFont *font = [UIFont systemFontOfSize:maxDesiredFontSize];
    
    for (int i = maxDesiredFontSize; i > minFontSize; --i)
    {
        font = [font fontWithSize:i];
        
        CGSize bounds = CGSizeMake(labelWidth, MAXFLOAT);
        CGRect textRect = [self.cc.card.name boundingRectWithSize:bounds
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName: font}
                                                          context:nil];

        if (textRect.size.height <= labelRequiredHeight)
        {
            break;
        }
    }
    self.nameLabel.font = font;
    
    self.altArtButton.hidden = self.cc.card.altCard == nil;
}

-(void) showAltArt:(id)sender
{
    [self.cell toggleImage];
}

-(void) copiesChanged:(id)sender
{
    int count = self.copiesStepper.value;
    BOOL delete = count == 0;
    
    self.cc.count = count;
    if (delete)
    {
        [CardImagePopup dismiss];
        
        if (self.cc.card.type == NRCardTypeIdentity)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:SELECT_IDENTITY object:self];
            return;
        }
    }
    else
    {
        self.copiesLabel.text = [NSString stringWithFormat:@"×%d", self.cc.count];
    }
    
    self.copiesLabel.textColor = [UIColor blackColor];
    if ([self.cc.card.setCode isEqualToString:@"core"])
    {
        NSInteger cores = [[NSUserDefaults standardUserDefaults] integerForKey:NUM_CORES];
        NSInteger owned = cores * self.cc.card.quantity;
        
        if (owned < self.cc.count)
        {
            self.copiesLabel.textColor = [UIColor redColor];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_LOADED object:self];
}

@end
