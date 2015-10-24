//
//  IdentityCardView.h
//  Net Deck
//
//  Created by Gereon Steffens on 26.08.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Card;

@interface IdentityCardView : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UIButton* selectButton;

@property (nonatomic) Card* card;

@end
