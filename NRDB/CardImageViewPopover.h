//
//  CardImageViewPopover.h
//  NRDB
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface CardImageViewPopover : UIViewController<UIPopoverControllerDelegate>

+(void) showForCard:(Card*)card fromRect:(CGRect)rect inView:(UIView*)vc;
+(void) dismiss;

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

@end
