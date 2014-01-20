//
//  CardCell.m
//  NRDB
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"
#import "CardCounter.h"
#import "Faction.h"
#import "CardType.h"
#import "CGRectUtils.h"
#import "Notifications.h"

@implementation CardCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

-(void) copiesChanged:(UIStepper*)sender
{
    int copies = sender.value;
    self.cardCounter.count = copies;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
}

-(void) setCardCounter:(CardCounter *)cardCounter
{
    self->_cardCounter = cardCounter;
    self.copiesStepper.value = cardCounter.count;
}

@end
