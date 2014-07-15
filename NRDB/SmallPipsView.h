//
//  SmallPipsView.h
//  NRDB
//
//  Created by Gereon Steffens on 15.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SmallPipsView : UIView

@property IBOutlet UIView* pipNW;
@property IBOutlet UIView* pipNE;
@property IBOutlet UIView* pipSW;
@property IBOutlet UIView* pipSE;
@property IBOutlet UIView* pipCenter;

-(void) setValue:(int)value;
-(void) setColor:(UIColor*)color;

@end
