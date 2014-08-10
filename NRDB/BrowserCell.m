//
//  BrowserCell.m
//  NRDB
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <EXTScope.h>
#import "BrowserCell.h"
#import "NRActionSheet.h"
#import "Notifications.h"
#import "Card.h"

@implementation BrowserCell

-(void) moreClicked:(UIButton*)sender
{
    NRActionSheet* sheet = [[NRActionSheet alloc] initWithTitle:nil
                                                       delegate:nil
                                              cancelButtonTitle:@""
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:l10n(@"Find decks using this card"), l10n(@"New deck with this card"), nil];
    
    CGRect rect = sender.frame;
    @weakify(self);
    [sheet showFromRect:rect inView:self animated:NO action:^(NSInteger buttonIndex) {
        if (buttonIndex == sheet.cancelButtonIndex)
        {
            return;
        }
        
        @strongify(self);
        NSString* name = buttonIndex == 0 ? BROWSER_FIND : BROWSER_NEW;
        // NSLog(@"send %@ %@", name, self.card.code);
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:@{ @"code": self.card.code }];
    }];
}


@end
