//
//  CardImageViewPopover.h
//  NRDB
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Card;

@interface CardImageViewPopover : UIViewController<UIPopoverControllerDelegate>

+(void) showForCard:(Card*)card fromRect:(CGRect)rect inView:(UIView*)vc;
+(void) dismiss;

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UIButton* toggleButton;

@property IBOutlet UIView* detailView;
@property IBOutlet UILabel* cardName;
@property IBOutlet UILabel* cardType;
@property IBOutlet UITextView* cardText;

@property IBOutlet UILabel* label1;
@property IBOutlet UILabel* label2;
@property IBOutlet UILabel* label3;
@property IBOutlet UIImageView* icon1;
@property IBOutlet UIImageView* icon2;
@property IBOutlet UIImageView* icon3;

-(IBAction) toggleImage:(id)sender;

+(void) monitorKeyboard;

@end
