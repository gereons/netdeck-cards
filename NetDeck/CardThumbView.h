//
//  CardThumbView.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.05.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//
//  used in draw simulator & identity picker
//

@interface CardThumbView : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property (nonatomic) Card* card;

@end
