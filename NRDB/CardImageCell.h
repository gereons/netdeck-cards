//
//  CardImageCell.h
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface CardImageCell : UICollectionViewCell

@property Card* card;
@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UILabel* copiesLabel;

-(void) toggleImage;
-(void) loadImage:(Card*)card;

@end
