//
//  CardImageCell.h
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card, CardCounter;

@interface CardImageCell : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UILabel* copiesLabel;
@property IBOutlet UIButton* toggleButton;

@property (nonatomic) CardCounter* cc;

-(IBAction)toggleImage:(id)sender;

-(void) loadImage;

@end
