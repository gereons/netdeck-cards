//
//  CardFilterThumbView.h
//  NRDB
//
//  Created by Gereon Steffens on 31.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CardFilterThumbView : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UILabel* countLabel;
@property IBOutlet UIButton* addButton;
@property IBOutlet UILabel* nameLabel;

@end
