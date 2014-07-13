//
//  CardThumbView.h
//  NRDB
//
//  Created by Gereon Steffens on 24.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//
//  used in draw simulator & identity picker
//

#import <UIKit/UIKit.h>

@class Card;
@interface CardThumbView : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

@property (nonatomic) Card* card;
@end
