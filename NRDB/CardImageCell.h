//
//  CardImageCell.h
//  NRDB
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card, CardCounter;

@interface CardImageCell : UICollectionViewCell

@property IBOutlet UIImageView* image1;
@property IBOutlet UIImageView* image2;
@property IBOutlet UIImageView* image3;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UILabel* copiesLabel;
@property IBOutlet UIButton* toggleButton;

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

@property (nonatomic) CardCounter* cc;

-(IBAction)toggleImage:(id)sender;

-(void) setImageStack:(UIImage*)img;
-(void) loadImage;

@end
