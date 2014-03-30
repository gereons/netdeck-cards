//
//  DeckImport.m
//  NRDB
//
//  Created by Gereon Steffens on 01.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckImport.h"
#import "Deck.h"
#import "Card.h"
#import "SettingsKeys.h"
#import "Notifications.h"
#import <AFNetworking.h>
#import <EXTScope.h>

@interface DeckImport()

@property UIAlertView* alert;
@property AFHTTPRequestOperationManager* manager;
@property BOOL downloadStopped;
@property Deck* deck;
@property NSString* deckId;

@end

@implementation DeckImport

static DeckImport* instance;

+(DeckImport*) sharedInstance
{
    if (instance == nil)
    {
        instance = [DeckImport new];
    }
    return instance;
}


+(void) updateCount
{
    NSInteger c = [UIPasteboard generalPasteboard].changeCount;
    
    [[NSUserDefaults standardUserDefaults] setInteger:c forKey:CLIP_CHANGE_COUNT];
}

+(void) checkClipboardForDeck
{
    DeckImport* di = [DeckImport sharedInstance];
    [di checkClipboardForDeck];
}

-(void) checkClipboardForDeck
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    NSInteger lastChange = [[NSUserDefaults standardUserDefaults] integerForKey:CLIP_CHANGE_COUNT];
    if (lastChange == pasteboard.changeCount)
    {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:pasteboard.changeCount forKey:CLIP_CHANGE_COUNT];
    
    NSString* clip = pasteboard.string;

    if (clip.length == 0)
    {
        return;
    }
    
    NSArray* lines = [clip componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    self.deck = nil;
    
    self.deckId = [self checkForDeckURL:lines];
    if (self.deckId)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:l10n(@"Detected a deck list URL in your clipboard. Download and import this deck?")
                                                       delegate:self
                                              cancelButtonTitle:l10n(@"No")
                                              otherButtonTitles:l10n(@"Yes"), nil];
        alert.tag = NO;
        [alert show];
        return;
    }
    else
    {
        self.deck = [self checkForTextDeck:lines];
        
        if (self.deck != nil)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:l10n(@"Detected a deck list in your clipboard. Import this deck?")
                                                           delegate:self
                                                  cancelButtonTitle:l10n(@"No")
                                                  otherButtonTitles:l10n(@"Yes"), nil];
            alert.tag = NO;
            [alert show];
        }
    }
}

-(NSString*) checkForDeckURL:(NSArray*) lines
{
    // a netrunnerdb.com decklist url looks like this:
    // http://netrunnerdb.com/en/decklist/3124/in-a-red-dress-and-alone-jamieson-s-store-champ-deck-#
    
    NSRegularExpression* urlRegex = [NSRegularExpression regularExpressionWithPattern:@"http://netrunnerdb.com/../decklist/(\\d*)/.*" options:0 error:nil];
    
    for (NSString* line in lines)
    {
        NSTextCheckingResult* match = [urlRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (match.numberOfRanges == 2)
        {
            NSString* deckId = [line substringWithRange:[match rangeAtIndex:1]];
            
            return deckId;
        }
    }

    return nil;
}

-(Deck*) checkForTextDeck:(NSArray*)lines
{
    NSArray* cards = [Card allCards];
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"^([0-9])x" options:0 error:nil];
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:@" x([0-9])" options:0 error:nil];
    
    Deck* deck = [Deck new];
    for (NSString* line in lines)
    {
        for (Card* c in cards)
        {
            if ([line rangeOfString:c.name options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                if (c.type == NRCardTypeIdentity)
                {
                    deck.identity = c;
                    // NSLog(@"found identity %@", c.name);
                }
                else
                {
                    NSTextCheckingResult *match = [regex1 firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
                    if (!match)
                    {
                        match = [regex2 firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
                    }
                    
                    if (match.numberOfRanges == 2)
                    {
                        NSString* count = [line substringWithRange:[match rangeAtIndex:1]];
                        // NSLog(@"found card %@ x %@", count, c.name);
                        
                        int cnt = [count intValue];
                        if (cnt > 0 && cnt < 4)
                        {
                            [deck addCard:c copies:cnt];
                        }
                        
                        break;
                    }
                }
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

#pragma mark alertview

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    BOOL stopAlert = alertView.tag;
    
    if (stopAlert)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        self.downloadStopped = YES;
        self.alert = nil;
        
        [self.manager.operationQueue cancelAllOperations];
        return;
    }
    
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        return;
    }
    
    if (self.deck)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:IMPORT_DECK object:self userInfo:@{ @"deck": self.deck }];
    }
    else if (self.deckId)
    {
        [self downloadDeck:self.deckId];
    }
    self.deck = nil;
    self.deckId = nil;
}

#pragma mark deck data download

-(void) downloadDeck:(NSString*)deckId
{
    self.alert = [[UIAlertView alloc] initWithTitle:l10n(@"Downloading Deck") message:nil delegate:self cancelButtonTitle:@"Stop" otherButtonTitles:nil];
    UIActivityIndicatorView* act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [act startAnimating];
    [self.alert setValue:act forKey:@"accessoryView"];
    self.alert.tag = YES;
    [self.alert show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self performSelector:@selector(doDownloadDeck:) withObject:deckId afterDelay:0.01];
}

-(void) doDownloadDeck:(NSString*)deckId
{
    NSString* deckUrl = [NSString stringWithFormat:@"http://netrunnerdb.com/api/decklist/%@", deckId];
    BOOL __block ok = NO;
    self.downloadStopped = NO;
    
    self.manager = [AFHTTPRequestOperationManager manager];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    @weakify(self);
    [self.manager GET:deckUrl parameters:nil
              success:^(AFHTTPRequestOperation* operation, id responseObject) {
                  @strongify(self);
                  if (!self.downloadStopped)
                  {
                      // NSLog(@"deck successfully downloaded");
                      ok = [self parseDecklist:responseObject];
                  }
                  [self downloadFinished:ok];
              }
              failure:^(AFHTTPRequestOperation* operation, NSError* error) {
                  @strongify(self);
                  // NSLog(@"download failed %@", operation);
                  [self downloadFinished:NO];
              }
     ];
}

-(void) downloadFinished:(BOOL)ok
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.alert dismissWithClickedButtonIndex:-1 animated:NO];
}

-(BOOL) parseDecklist:(NSDictionary*) decklist
{
    Deck* deck = [Deck new];
    
    deck.name = [decklist objectForKey:@"name"];
    NSDictionary* cards = [decklist objectForKey:@"cards"];
    for (NSString* code in [cards allKeys])
    {
        int qty = [[cards objectForKey:code] intValue];
        Card* card = [Card cardByCode:code];
        if (card)
        {
            if (card.type == NRCardTypeIdentity)
            {
                deck.identity = card;
                deck.role = card.role;
            }
            else
            {
                [deck addCard:card copies:qty];
            }
        }
    }
    
    if (deck.identity != nil && deck.cards.count > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:IMPORT_DECK object:self userInfo:@{ @"deck": deck }];
        return YES;
    }
    return NO;
}

@end
