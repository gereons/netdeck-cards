//
//  CardImageViewPopover.h
//  NRDB
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Card;

@interface CardImageViewPopover : UIViewController<UIPopoverControllerDelegate>

+(void) showForCard:(Card*)card fromRect:(CGRect)rect inView:(UIView*)vc;
+(BOOL) dismiss; // return YES if popup was visible

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
