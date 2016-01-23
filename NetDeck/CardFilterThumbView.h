//
//  CardFilterThumbView.h
//  Net Deck
//
//  Created by Gereon Steffens on 31.05.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface CardFilterThumbView : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UILabel* countLabel;
@property IBOutlet UIButton* addButton;
@property IBOutlet UILabel* nameLabel;

@property (nonatomic) Card* card;

@end
