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

@property CardCounter* cc;

-(void) toggleImage;
-(void) loadImage;

@end
