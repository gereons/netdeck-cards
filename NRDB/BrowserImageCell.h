//
//  BrowserImageCell.h
//  NRDB
//
//  Created by Gereon Steffens on 09.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Card;

@interface BrowserImageCell : UICollectionViewCell

@property IBOutlet UIImageView* image;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

@property IBOutlet UIView* detailView;
@property IBOutlet UILabel* cardName;
@property IBOutlet UILabel* cardType;
@property IBOutlet UITextView* cardText;

@property IBOutlet UILabel* label1;
@property IBOutlet UILabel* label2;
@property IBOutlet UILabel* label3;
@property IBOutlet UIImageView* icon1;
@property IBOutlet UIImageView* icon2;
@property IBOutlet UIImageView* icon3;

@property (nonatomic) Card* card;

@end
