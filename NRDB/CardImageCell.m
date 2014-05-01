//
//  CardImageCell.m
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CardImageCell.h"
#import "ImageCache.h"
#import "CardCounter.h"
#import "Faction.h"
#import "CardType.h"

@implementation CardImageCell

/*
 TODO: draw stack border around card
 see https://stackoverflow.com/questions/6434925/how-to-draw-uibezierpaths
 see http://ronnqvi.st/thinking-like-a-bzier-path/
 */

-(void) awakeFromNib
{
    // remove all constraints IB has generated
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self removeConstraints:self.constraints];
    [self.detailView removeConstraints:self.detailView.constraints];
    
    NSDictionary* views = @{
                            @"image": self.imageView,
                            @"activity": self.activityIndicator,
                            @"toggle": self.toggleButton,
                            @"label": self.copiesLabel,
                            @"details": self.detailView,
                            };
    
    NSArray* constraints = @[
                             @"H:|[image]|",
                             @"H:|[label]|",
                             @"H:[toggle(28)]",
                             @"H:|[details]|",
                             @"V:|[image][label(20)]|",
                             @"V:|[details(==image)]",
                             @"V:[toggle(34)]",
                            ];
    
    // see http://stackoverflow.com/questions/12873372/centering-a-view-in-its-superview-using-visual-format-language
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.imageView
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.f constant:0.f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.imageView
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.f constant:0.f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.toggleButton
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.imageView
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.f constant:0.f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.toggleButton
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.imageView
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.f constant:0.f]];
    
    for (NSString* c in constraints)
    {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:c options:0 metrics:nil views:views]];
    }
    
    [self.detailView removeConstraints:self.detailView.constraints];
    views = @{ @"name": self.cardName,
               @"type": self.cardType,
               @"text": self.cardText,
               @"label1": self.label1,
               @"label2": self.label2,
               @"label3": self.label3,
               @"icon1": self.icon1,
               @"icon2": self.icon2,
               @"icon3": self.icon3,
               };

    constraints = @[
                    @"H:|-[name]-|",
                    @"H:|-[type]-|",
                    @"H:|-[text]-|",
                    @"H:|-[label1][icon1]",
                    @"H:[label3][icon3]-|",
                    @"V:|-[name]-[label1]-[type]-[text]-|",
                    @"V:|-[name]-[label2]",
                    @"V:|-[name]-[label3]",
                    @"V:|-[name]-[icon1]",
                    @"V:|-[name]-[icon2]",
                    @"V:|-[name]-[icon3]",
                    ];
    for (NSString* c in constraints)
    {
        [self.detailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:c options:0 metrics:nil views:views]];
    }
    
    [self.detailView addConstraint:[NSLayoutConstraint constraintWithItem:self.label2
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.detailView
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.f constant:-7.f]];
    [self.detailView addConstraint:[NSLayoutConstraint constraintWithItem:self.icon2
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.detailView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.f constant:8.f]];
    
    // add parallax effect to cells
    UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	
	float depth = 10;
	effectX.maximumRelativeValue = @(depth);
	effectX.minimumRelativeValue = @(-depth);
	effectY.maximumRelativeValue = @(depth);
	effectY.minimumRelativeValue = @(-depth);
	
	[self addMotionEffect:effectX];
	[self addMotionEffect:effectY];
}

-(void) setCc:(CardCounter *)cc
{
    self->_cc = cc;
    self.toggleButton.hidden = self.cc.card.altCard == nil;
    self.toggleButton.layer.masksToBounds = YES;
    self.toggleButton.layer.cornerRadius = 3;
    [self.toggleButton setImage:[ImageCache altArtIcon:self.cc.showAltArt] forState:UIControlStateNormal];
}

-(void) toggleImage:(id)sender
{
    self.cc.showAltArt = !self.cc.showAltArt;
    [self.toggleButton setImage:[ImageCache altArtIcon:self.cc.showAltArt] forState:UIControlStateNormal];
    [self loadImage];
}

-(void) loadImage
{
    Card* card = self.cc.showAltArt ? self.cc.card.altCard : self.cc.card;
    [self loadImage:card];
}

-(void) loadImage:(Card*)card
{
    [self.activityIndicator startAnimating];
    [[ImageCache sharedInstance] getImageFor:card
                                     completion:^(Card* card, UIImage* img, BOOL placeholder) {
                                         [self.activityIndicator stopAnimating];
                                         if ([self.cc.card.name isEqual:card.name])
                                         {
                                             self.imageView.image = img;
                                         }
                                         else
                                         {
                                             NSLog(@"got img %@ for %@", card.name, self.cc.card.name);
                                         }
                                         
                                         self.detailView.hidden = !placeholder;
                                         if (placeholder)
                                         {
                                             [self setupDetailView];
                                         }
                                     }];
}

-(void) setupDetailView
{
    self.detailView.hidden = NO;
    self.detailView.backgroundColor = [UIColor colorWithWhite:1 alpha:.7];
    
    Card* card = self.cc.card;
    self.cardName.text = card.name;
    self.cardText.attributedText = card.attributedText;
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    NSString* subtype = card.subtype;
    if (subtype)
    {
        self.cardType.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        self.cardType.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }
    
    // labels from top: cost/strength/mu
    switch (card.type)
    {
        case NRCardTypeIdentity:
            self.label1.text = [@(card.minimumDecksize) stringValue];
            self.icon1.image = [ImageCache cardIcon];
            self.label2.text = [@(card.influenceLimit) stringValue];
            self.icon2.image = [ImageCache influenceIcon];
            if (card.role == NRRoleRunner)
            {
                self.label3.text = [NSString stringWithFormat:@"%d", card.baseLink];
                self.icon3.image = [ImageCache linkIcon];
            }
            else
            {
                self.label3.text = @"";
                self.icon3.image = nil;
            }
            break;
            
        case NRCardTypeProgram:
        case NRCardTypeResource:
        case NRCardTypeEvent:
        case NRCardTypeHardware:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%d", card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = card.strength != -1 ? [NSString stringWithFormat:@"%d", card.strength] : @"";
            self.icon2.image = card.strength != -1 ? [ImageCache strengthIcon] : nil;
            self.label3.text = card.mu != -1 ? [NSString stringWithFormat:@"%d", card.mu] : @"";
            self.icon3.image = card.mu != -1 ? [ImageCache muIcon] : nil;
            break;
            
        case NRCardTypeIce:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%d", card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = card.strength != -1 ? [NSString stringWithFormat:@"%d", card.strength] : @"";
            self.icon3.image = card.strength != -1 ? [ImageCache strengthIcon] : nil;
            break;
            
        case NRCardTypeAgenda:
            self.label1.text = [NSString stringWithFormat:@"%d", card.advancementCost];
            self.icon1.image = [ImageCache difficultyIcon];
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = [NSString stringWithFormat:@"%d", card.agendaPoints];
            self.icon3.image = [ImageCache apIcon];
            break;
            
        case NRCardTypeAsset:
        case NRCardTypeOperation:
        case NRCardTypeUpgrade:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%d", card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = card.trash != -1 ? [NSString stringWithFormat:@"%d", card.trash] : @"";
            self.icon3.image = card.trash != -1 ? [ImageCache trashIcon] : nil;
            break;
            
        case NRCardTypeNone:
            NSAssert(NO, @"this can't happen");
            break;
    }
}


@end
