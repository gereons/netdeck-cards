//
//  CardThumbView.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.05.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//
//  used in draw simulator & identity picker
//

@interface CardThumbView : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property (nonatomic) Card* card;

@end
