//
//  CardImageViewCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface CardImageViewCell : UICollectionViewCell

@property IBOutlet UIImageView* imageView;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UILabel* countLabel;

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

@property BOOL showAsDifferences;

-(void) setCard:(Card*)card;
-(void) setCard:(Card*)card andCount:(NSInteger)count;

@end
