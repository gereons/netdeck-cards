//
//  CardImagePopup.m
//  Net Deck
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardImagePopup.h"
#import "CardImageCell.h"

@interface CardImagePopup ()

@property CardCounter* cc;
@property Deck* deck;
@property NSUInteger prevCount;

@end

@implementation CardImagePopup

static CardImagePopup* popover;

+(CardImagePopup*) showForCard:(CardCounter *)cc inDeck:(Deck*)deck fromRect:(CGRect)rect inViewController:(UIViewController*)vc subView:(UIView*)view direction:(UIPopoverArrowDirection)direction
{
    popover = [[CardImagePopup alloc] initWithCard:cc andDeck:deck];
    
    popover.modalPresentationStyle = UIModalPresentationPopover;
    popover.popoverPresentationController.sourceRect = rect;
    popover.popoverPresentationController.sourceView = view;
    popover.popoverPresentationController.permittedArrowDirections = direction;
    
    popover.preferredContentSize = popover.view.frame.size;
    
    [vc presentViewController:popover animated:NO completion:nil];

    return popover;
}

+(void) dismiss
{
    if (popover)
    {
        [popover dismissViewControllerAnimated:NO completion:nil];
        popover = nil;
    }
}

- (id)initWithCard:(CardCounter*)cc andDeck:(Deck*)deck
{
    self = [super initWithNibName:@"CardImagePopup" bundle:nil];
    if (self)
    {
        self.cc = cc;
        self.prevCount = cc.count;
        self.deck = deck;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.copiesStepper.maximumValue = self.deck.isDraft ? 100 : self.cc.card.maxPerDeck;
    self.copiesStepper.value = self.cc.count;
    self.copiesLabel.text = [NSString stringWithFormat:@"×%lu", (unsigned long)self.cc.count];
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
}

-(void) copiesChanged:(id)sender
{
    int count = self.copiesStepper.value;
    BOOL delete = count == 0;
    
    NSInteger diff = count - self.prevCount;
    [self.deck addCard:self.cc.card copies:diff];
    self.prevCount = count;
    
    if (delete)
    {
        [CardImagePopup dismiss];
        
        if (self.cc.card.type == NRCardTypeIdentity)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.SELECT_IDENTITY object:self];
            return;
        }
    }
    else
    {
        self.copiesLabel.text = [NSString stringWithFormat:@"×%lu", (unsigned long)count];
    }
    
    self.copiesLabel.textColor = [UIColor blackColor];
    if (!self.deck.isDraft && self.cc.card.owned < count)
    {
        self.copiesLabel.textColor = [UIColor redColor];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DECK_CHANGED object:self];
}

@end
