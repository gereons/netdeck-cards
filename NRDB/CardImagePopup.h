//
//  CardImagePopup.h
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CardCounter;

@interface CardImagePopup : UIViewController

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* copiesLabel;
@property IBOutlet UIStepper* copiesStepper;

-(IBAction) copiesChanged:(id)sender;

+(void) showForCard:(CardCounter*)card fromRect:(CGRect)rect inView:(UIView*)vc;
+(void) dismiss;

@end
