//
//  CardImageViewCell.h
//  NRDB
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Card;

@interface CardImageViewCell : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

@property (nonatomic) Card* card;

@end
