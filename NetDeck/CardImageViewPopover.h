//
//  CardImageViewPopover.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface CardImageViewPopover : UIViewController<UIPopoverPresentationControllerDelegate>

+(void) showForCard:(Card*)card fromRect:(CGRect)rect inViewController:(UIViewController*)vc subView:(UIView*)view;
+(BOOL) dismiss; // return YES if popup was visible

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

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

+(void) monitorKeyboard;

@end
