//
//  DeckImport.m
//  NRDB
//
//  Created by Gereon Steffens on 01.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <EXTScope.h>
#import <SDCAlertView.h>
#import <AFNetworking.h>

#import "DeckImport.h"
#import "Deck.h"
#import "CardManager.h"
#import "SettingsKeys.h"
#import "Notifications.h"
#import "OctgnImport.h"

#define IMPORT_ALWAYS   NO  // set to yes for easier debugging

#if !defined(DEBUG)
#if IMPORT_ALWAYS
#warning resetting IMPORT_ALWAYS
#undef IMPORT_ALWAYS
#define IMPORT_ALWAYS   NO
#endif
#endif

typedef NS_ENUM(NSInteger, DeckBuilderSite)
{
    DeckBuilderSiteNone,
    DeckBuilderSiteNetrunnerDB,
    DeckBuilderSiteMeteor
};

@interface DeckSource : NSObject
@property NSString* deckId;
@property DeckBuilderSite site;
@end
@implementation DeckSource
@end

@interface DeckImport()

@property SDCAlertView* alert;
@property AFHTTPRequestOperationManager* manager;
@property BOOL downloadStopped;
@property DeckSource* deckSource;
@property Deck* deck;

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
    if (lastChange == pasteboard.changeCount && !IMPORT_ALWAYS)
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
    
    self.deckSource = [self checkForNetrunnerDbDeckURL:lines];    
    if (!self.deckSource)
    {
        self.deckSource = [self checkForMeteorDeckURL:lines];
    }
    
    SDCAlertView* alert = nil;
    if (self.deckSource)
    {
        if (self.deckSource.site == DeckBuilderSiteNetrunnerDB)
        {
            alert = [SDCAlertView alertWithTitle:nil
                                         message:l10n(@"Detected a NetrunnerDB.com deck list URL in your clipboard. Download and import this deck?")
                                         buttons:@[l10n(@"No"), l10n(@"Yes")]];
        }
        else if (self.deckSource.site == DeckBuilderSiteMeteor)
        {
            alert = [SDCAlertView alertWithTitle:nil
                                         message:l10n(@"Detected a meteor deck list URL in your clipboard. Download and import this deck?")
                                         buttons:@[l10n(@"No"), l10n(@"Yes")]];
        }
    }
    else
    {
        self.deck = [self checkForTextDeck:lines];
        
        if (self.deck != nil)
        {
            alert = [SDCAlertView alertWithTitle:nil
                                         message:l10n(@"Detected a deck list in your clipboard. Import this deck?")
                                         buttons:@[l10n(@"No"), l10n(@"Yes")]];
        }
    }
    
    if (alert)
    {
        @weakify(self);
        alert.didDismissHandler = ^(NSInteger buttonIndex) {
            @strongify(self);
            if (buttonIndex == 1) // yes
            {
                if (self.deck)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:IMPORT_DECK object:self userInfo:@{ @"deck": self.deck }];
                }
                else if (self.deckSource)
                {
                    [self downloadDeck:self.deckSource];
                }
                self.deck = nil;
                self.deckSource = nil;
            }
        };
    }
}

-(DeckSource*) checkForNetrunnerDbDeckURL:(NSArray*) lines
{
    // a netrunnerdb.com decklist url looks like this:
    // http://netrunnerdb.com/en/decklist/3124/in-a-red-dress-and-alone-jamieson-s-store-champ-deck-#
    
    NSRegularExpression* urlRegex = [NSRegularExpression regularExpressionWithPattern:@"http://netrunnerdb.com/../decklist/(\\d*)/.*" options:0 error:nil];
    
    for (NSString* line in lines)
    {
        NSTextCheckingResult* match = [urlRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (match.numberOfRanges == 2)
        {
            DeckSource* src = [[DeckSource alloc] init];
            src.deckId = [line substringWithRange:[match rangeAtIndex:1]];
            src.site = DeckBuilderSiteNetrunnerDB;
            return src;
        }
    }

    return nil;
}

-(DeckSource*) checkForMeteorDeckURL:(NSArray*) lines
{
    // a netrunner.meteor.com decklist url looks like this:
    // http://netrunner.meteor.com/decks/yBMJ3GL6FPozt9nkQ/
    
    NSRegularExpression* urlRegex = [NSRegularExpression regularExpressionWithPattern:@"http://netrunner.meteor.com/decks/(.*)/" options:0 error:nil];
    
    for (NSString* line in lines)
    {
        NSTextCheckingResult* match = [urlRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (match.numberOfRanges == 2)
        {
            DeckSource* src = [[DeckSource alloc] init];
            src.deckId = [line substringWithRange:[match rangeAtIndex:1]];
            src.site = DeckBuilderSiteMeteor;
            return src;
        }
    }
    
    return nil;
}

-(Deck*) checkForTextDeck:(NSArray*)lines
{
    NSArray* cards = [CardManager allCards];
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"^([0-9])x" options:0 error:nil]; // start with "1x ..."
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:@" x([0-9])" options:0 error:nil]; // end with "... x3"
    NSRegularExpression *regex3 = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]) " options:0 error:nil]; // start with "1 ..."
    
    NSString* name;
    
    Deck* deck = [[Deck alloc] init];
    for (NSString* line in lines)
    {
        if (name == nil)
        {
            name = line;
        }
        
        for (Card* c in cards)
        {
            NSUInteger loc = [line rangeOfString:c.name options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location;
            
            if (loc != NSNotFound)
            {
                if (c.type == NRCardTypeIdentity)
                {
                    [deck addCard:c copies:1];
                    // NSLog(@"found identity %@", c.name);
                }
                else
                {
                    NSTextCheckingResult *match = [regex1 firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
                    if (!match)
                    {
                        match = [regex2 firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
                    }
                    if (!match)
                    {
                        match = [regex3 firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
                    }
                    
                    if (match.numberOfRanges == 2)
                    {
                        NSString* count = [line substringWithRange:[match rangeAtIndex:1]];
                        // NSLog(@"found card %@ x %@", count, c.name);
                        
                        int cnt = [count intValue];
                        int max = deck.isDraft ? 100 : 4;
                        if (cnt > 0 && max)
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
        deck.name = name;
        
        return deck;
    }
    else
    {
        return nil;
    }
}

#pragma mark deck data download

-(void) downloadDeck:(DeckSource*) deckSource
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, SDCAlertViewWidth, 20)];
    UIActivityIndicatorView* act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    act.center = CGPointMake(SDCAlertViewWidth/2, view.frame.size.height/2);
    [act startAnimating];
    [view addSubview:act];
    
    self.alert = [SDCAlertView alertWithTitle:l10n(@"Downloading Deck") message:nil subview:view buttons:@[l10n(@"Stop")]];
    
    @weakify(self);
    self.alert.didDismissHandler = ^(NSInteger buttonIndex) {
        @strongify(self);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        self.downloadStopped = YES;
        self.alert = nil;
        
        [self.manager.operationQueue cancelAllOperations];
        return;
    };

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (deckSource.site == DeckBuilderSiteNetrunnerDB)
    {
        [self performSelector:@selector(doDownloadDeckFromNetrunnerDb:) withObject:deckSource.deckId afterDelay:0.01];
    }
    else
    {
        [self performSelector:@selector(doDownloadDeckFromMeteor:) withObject:deckSource.deckId afterDelay:0.01];
    }
}

-(void) doDownloadDeckFromNetrunnerDb:(NSString*)deckId
{
    TF_CHECKPOINT(@"deck d/l nrdb");
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
                      ok = [self parseJsonDecklist:responseObject];
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

-(void) doDownloadDeckFromMeteor:(NSString*)deckId
{
    TF_CHECKPOINT(@"deck d/l meteor");
    NSString* deckUrl = [NSString stringWithFormat:@"http://netrunner.meteor.com/deckexport/octgn/%@/", deckId];
    BOOL __block ok = NO;
    self.downloadStopped = NO;
    
    self.manager = [AFHTTPRequestOperationManager manager];
    self.manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
    NSMutableSet* contentTypes = [NSMutableSet setWithSet:self.manager.responseSerializer.acceptableContentTypes];
    [contentTypes addObject:@"application/force-download"];
    self.manager.responseSerializer.acceptableContentTypes = contentTypes;
    
    @weakify(self);
    [self.manager GET:deckUrl parameters:nil
              success:^(AFHTTPRequestOperation* operation, id responseObject) {
                  @strongify(self);
                  if (!self.downloadStopped)
                  {
                      // NSLog(@"deck successfully downloaded");
                      
                      // filename comes in Content-Disposition header, which looks like
                      // Content-Disposition: attachment; filename=Copy%20of%20Weyland%20Speed.o8d
                      NSString* disposition = operation.response.allHeaderFields[@"Content-Disposition"];
                      NSString* filename;
                      NSRange range = [disposition rangeOfString:@"filename=" options:NSCaseInsensitiveSearch];
                      if (range.location != NSNotFound)
                      {
                          filename = [disposition substringFromIndex:range.location+9];
                          range = [filename rangeOfString:@".o8d" options:NSCaseInsensitiveSearch];
                          if (range.location !=NSNotFound)
                          {
                              filename = [filename substringToIndex:range.location];
                              filename = [filename stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                          }
                      }
                      
                      ok = [self parseOctgnDeck:responseObject filename:filename];
                  }
                  [self downloadFinished:ok];
              }
              failure:^(AFHTTPRequestOperation* operation, NSError* error) {
                  @strongify(self);
                  NSLog(@"download failed %@", operation);
                  [self downloadFinished:NO];
              }
     ];
}

-(void) downloadFinished:(BOOL)ok
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.alert dismissWithClickedButtonIndex:-1 animated:NO];
}

-(BOOL) parseJsonDecklist:(NSDictionary*) decklist
{
    Deck* deck = [[Deck alloc] init];
    
    deck.name = [decklist objectForKey:@"name"];
    
    NSString* notes = [decklist objectForKey:@"description"];
    if (notes.length > 0)
    {
        notes = [notes stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
        notes = [notes stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
        deck.notes = notes;
    }
    
    NSDictionary* cards = [decklist objectForKey:@"cards"];
    for (NSString* code in [cards allKeys])
    {
        int qty = [[cards objectForKey:code] intValue];
        Card* card = [Card cardByCode:code];
        if (card)
        {
            if (card.type == NRCardTypeIdentity)
            {
                deck.role = card.role;
            }
            [deck addCard:card copies:qty];
        }
    }
    
    if (deck.identity != nil && deck.cards.count > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:IMPORT_DECK object:self userInfo:@{ @"deck": deck }];
        return YES;
    }
    return NO;
}

-(BOOL) parseOctgnDeck:(NSXMLParser*)parser filename:(NSString*)filename
{
    OctgnImport* importer = [[OctgnImport alloc] init];
    Deck* deck = [importer parseOctgnDeckWithParser:parser];
    
    if (deck.identity != nil && deck.cards.count > 0)
    {
        // NSLog(@"got deck: %@ %d", deck.identity.name, deck.cards.count);
        // NSLog(@"name: %@", filename);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:IMPORT_DECK object:self userInfo:@{ @"deck": deck }];
        return YES;
    }
    return NO;
}

@end
