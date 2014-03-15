//
//  DeckImport.m
//  NRDB
//
//  Created by Gereon Steffens on 01.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckImport.h"
#import "Deck.h"
#import "SettingsKeys.h"

@implementation DeckImport

+(void) updateCount
{
    NSInteger c = [UIPasteboard generalPasteboard].changeCount;
    
    [[NSUserDefaults standardUserDefaults] setInteger:c forKey:CLIP_CHANGE_COUNT];
}

+(Deck*) parseClipboard
{
#warning check for netrunnerdb.com deck url also!
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    NSInteger lastChange = [[NSUserDefaults standardUserDefaults] integerForKey:CLIP_CHANGE_COUNT];
    if (lastChange == pasteboard.changeCount)
    {
        return nil;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:pasteboard.changeCount forKey:CLIP_CHANGE_COUNT];
    
    NSString* clip = pasteboard.string;
    if (clip.length == 0)
    {
        return nil;
    }
    
    NSArray* lines = [clip componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSArray* cards = [Card allCards];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)x" options:0 error:NULL];
    
    Deck* deck = [Deck new];
    for (NSString* line in lines)
    {
        for (Card* c in cards)
        {
            if ([line rangeOfString:c.name options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                NSTextCheckingResult *match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
                
                NSString* count = [line substringWithRange:[match rangeAtIndex:1]];
                // NSLog(@"found card %@ x %@", count, c.name);
                
                if (c.type == NRCardTypeIdentity)
                {
                    deck.identity = c;
                }
                else
                {
                    int cnt = [count intValue];
                    if (cnt > 0 && cnt < 4)
                    {
                        [deck addCard:c copies:cnt];
                    }
                }
                break;
            }
        }
    }
    
    if (deck.identity != nil && deck.cards.count > 0)
    {
        return deck;
    }
    else
    {
        return nil;
    }
}

@end
