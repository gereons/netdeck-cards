//
//  BrowserImageCell.h
//  NRDB
//
//  Created by Gereon Steffens on 09.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Card;

@interface BrowserImageCell : UICollectionViewCell

@property IBOutlet UIImageView* image;
@property IBOutlet UIButton* altArtButton;
@property IBOutlet UIActivityIndicatorView* activityIndicator;

-(void) loadImageFor:(Card*)card;

@end
