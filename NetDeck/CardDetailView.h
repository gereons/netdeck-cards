//
//  CardDetailView.h
//  Net Deck
//
//  Created by Gereon Steffens on 03.05.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

// since we can't have nice things (ie. multiple inheritance), this class mirrors the IBOutlet properties
// from CardImageViewPopover, CardImageCell, BrowserImageCell and CardImageViewCell - better than having to duplicate the code

// TODO for later: convert this to a category that uses objc_setAssociatedObject/obj_getAssociatedObject

@class CardImageViewPopover, CardImageCell, BrowserImageCell, CardImageViewCell;

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
+(void) setupDetailViewFromBrowser:(BrowserImageCell *)cell card:(Card*)card;
+(void) setupDetailViewFromIphone:(CardImageViewCell *)cell card:(Card*)card;

@end
