//
//  CardCell.m
//  NRDB
//
//  Created by Gereon Steffens on 27.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardCell.h"
#import "CardCounter.h"
#import "Notifications.h"

@implementation CardCell

-(void) copiesChanged:(UIStepper*)sender
{
    int copies = sender.value;
    self.cardCounter.count = copies;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_CHANGED object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:DECK_LOADED object:self];
}

@end
