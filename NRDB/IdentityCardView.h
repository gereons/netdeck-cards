//
//  IdentityCardView.h
//  NRDB
//
//  Created by Gereon Steffens on 26.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface IdentityCardView : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UIButton* selectButton;

@property (nonatomic) Card* card;

@end