//
//  CardCell.h
//  NRDB
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Deck, CardCounter;

@interface CardCell : UITableViewCell {
    @protected
    CardCounter* _cardCounter;
}

@property Deck* deck;
@property (nonatomic) CardCounter* cardCounter;

-(IBAction)copiesChanged:(id)sender;

@end
