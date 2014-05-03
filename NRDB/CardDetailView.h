//
//  CardDetailView.h
//  NRDB
//
//  Created by Gereon Steffens on 03.05.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Card, CardImageViewPopover, CardImageCell;

@interface CardDetailView : NSObject

@property Card* card;

@property UIView* detailView;
@property UILabel* cardName;
@property UILabel* cardType;
@property UITextView* cardText;

@property UILabel* label1;
@property UILabel* label2;
@property UILabel* label3;
@property UIImageView* icon1;
@property UIImageView* icon2;
@property UIImageView* icon3;

+(void) setupDetailViewFromPopover:(CardImageViewPopover*)popover card:(Card*)card;
+(void) setupDetailViewFromCell:(CardImageCell *)cell card:(Card*)card;

@end
