//
//  NRDB.m
//  Net Deck
//
//  Created by Gereon Steffens on 20.06.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@import SDCAlertView;
@import AFNetworking;

#import "EXTScope.h"
#import "NRDB.h"
#import "NRDBAuth.h"
#import "SettingsKeys.h"

@interface NRDB()
@property (strong) DecklistCompletionBlock decklistCompletionBlock;
@property (strong) SaveCompletionBlock saveCompletionBlock;
@property NSMutableDictionary* deckMap;
@property NSTimer* timer;
@end

@implementation NRDB

static NRDB* instance;
static NSDateFormatter* formatter;

+(NRDB*) sharedInstance
{
    if (!instance)
    {
        instance = [[NRDB alloc] init];
    }
    return instance;
}

+(void) initialize
{
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
}

+(void) clearSettings
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    [settings removeObjectForKey:NRDB_ACCESS_TOKEN];
    [settings removeObjectForKey:NRDB_REFRESH_TOKEN];
    [settings removeObjectForKey:NRDB_TOKEN_EXPIRY];
    [settings removeObjectForKey:NRDB_TOKEN_TTL];
    [settings setObject:@(NO) forKey:USE_NRDB];
    
    [settings synchronize];
    [[NRDB sharedInstance].timer invalidate];
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
}

#pragma mark autorization

-(void) authorizeWithCode:(NSString *)code completion:(AuthCompletionBlock)completionBlock
{
    // NSLog(@"auth code");
    // ?client_id=" CLIENT_ID "&client_secret=" CLIENT_SECRET "&grant_type=authorization_code&redirect_uri=" CLIENT_HOST "&code="
    
    NSDictionary* parameters = @{
        @"client_id": @CLIENT_ID,
        @"client_secret": @CLIENT_SECRET,
        @"grant_type": @"authorization_code",
        @"redirect_uri": @CLIENT_HOST,
        @"code": code
    };
    
    [self getAuthorization:parameters completion:completionBlock];
}

-(void) refreshToken:(AuthCompletionBlock)completionBlock
{
    // NSLog(@"refresh token");
    // ?client_id=" CLIENT_ID "&client_secret=" CLIENT_SECRET "&grant_type=refresh_token&redirect_uri=" CLIENT_HOST "&refresh_token="

    NSString* token = [[NSUserDefaults standardUserDefaults] stringForKey:NRDB_REFRESH_TOKEN];
    
    if (token == nil)
    {
        completionBlock(NO);
        return;
    }
    
    NSDictionary* parameters = @{
        @"client_id": @CLIENT_ID,
        @"client_secret":  @CLIENT_SECRET,
        @"grant_type": @"refresh_token",
        @"redirect_uri": @CLIENT_HOST,
        @"refresh_token": token
    };

    [self getAuthorization:parameters completion:completionBlock];
}

-(void) getAuthorization:(NSDictionary*)parameters completion:(AuthCompletionBlock)completionBlock
{
    BOOL foreground = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
    if (foreground && !APP_ONLINE)
    {
        completionBlock(NO);
        return;
    }
    
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:@TOKEN_URL parameters:parameters
         success:^(AFHTTPRequestOperation* operation, id responseObject) {
             // NSLog(@"auth response: %@", responseObject);
             BOOL ok = YES;
             
             NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
             NSString* token = responseObject[@"access_token"];
             if (token)
             {
                 [settings setObject:token forKey:NRDB_ACCESS_TOKEN];
             }
             else
             {
                 ok = NO;
             }
             
             token = responseObject[@"refresh_token"];
             if (token)
             {
                 [settings setObject:token forKey:NRDB_REFRESH_TOKEN];
             }
             else
             {
                 ok = NO;
             }
             NSNumber* exp = responseObject[@"expires_in"];
             [settings setObject:exp forKey:NRDB_TOKEN_TTL];
             NSDate* expiry = [[NSDate date] dateByAddingTimeInterval:[exp intValue]];
             [settings setObject:expiry forKey:NRDB_TOKEN_EXPIRY];
             
             if (!ok)
             {
                 [NRDB clearSettings];
             }
             [settings synchronize];
             
             // NSLog(@"nrdb (re)auth success, status: %d", ok);
             [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:BG_FETCH_INTERVAL];
             completionBlock(ok);
         }
         failure:^(AFHTTPRequestOperation* operation, NSError* error) {
             [NRDB clearSettings];
             
             // NSLog(@"nrdb (re)auth failed: %@", operation);
             [SDCAlertView alertWithTitle:nil
                                  message:l10n(@"Authorization at NetrunnerDB.com failed")
                                  buttons:@[ l10n(@"OK") ]];
             
             [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
             completionBlock(NO);
         }
    ];
}

-(void) refreshAuthentication
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if (![settings boolForKey:USE_NRDB] || !APP_ONLINE)
    {
        return;
    }
    
    if ([settings objectForKey:NRDB_REFRESH_TOKEN] == nil)
    {
        [NRDB clearSettings];
        return;
    }
    
    NSDate* expiry = [settings objectForKey:NRDB_TOKEN_EXPIRY];
    NSDate* now = [NSDate date];
    NSTimeInterval diff = [expiry timeIntervalSinceDate:now];
    diff -= 5*60; // 5 minutes overlap
    // NSLog(@"start nrdb auth refresh in %f seconds", diff);

    if (diff < 0)
    {
        // token is expired, refresh now
        [self timedRefresh:nil];
    }
    else
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:diff
                                                      target:self
                                                    selector:@selector(timedRefresh:)
                                                    userInfo:nil
                                                     repeats:NO];
    }
}

-(void) backgroundRefreshAuthentication:(BackgroundFetchCompletionBlock)completionHandler
{
    // NSLog(@"start bg fetch");
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    if (![settings boolForKey:USE_NRDB])
    {
        // NSLog(@"no nrdb account");
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    if ([settings objectForKey:NRDB_REFRESH_TOKEN] == nil)
    {
        // NSLog(@"no token");
        [NRDB clearSettings];
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }

    [self refreshToken:^(BOOL ok) {
        // NSLog(@"refresh: %d", ok);
        completionHandler(ok ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultFailed);
    }];
}

-(void) timedRefresh:(NSTimer*) timer
{
    [self refreshToken:^(BOOL ok) {
        NSTimeInterval ti = 300;
        if (ok)
        {
            NSNumber* ttl = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_TOKEN_TTL];
            ti = [ttl floatValue];
            ti -= 300; // 5 minutes before expiry
            
        }
        self.timer = [NSTimer scheduledTimerWithTimeInterval:ti
                                                      target:self
                                                    selector:@selector(timedRefresh:)
                                                    userInfo:nil
                                                     repeats:NO];
    }];
}

-(void) stopRefresh
{
    // NSLog(@"stopping refresh timer");
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark deck list

-(void) decklist:(DecklistCompletionBlock)completionBlock
{
    self.decklistCompletionBlock = completionBlock;
    [self getDecks];
}

-(void) getDecks
{
    NSString* decksUrl = @"http://netrunnerdb.com/api_oauth2/decks";
    
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:NRDB_ACCESS_TOKEN];
    NSError* error;
    NSDictionary* params = @{
        @"access_token" : accessToken ? accessToken : @""
    };
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                                 URLString:decksUrl
                                                                                parameters:params
                                                                                     error:&error];
    // bypass cache!
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        [self finishedDecklist:YES decks:responseObject];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(self);
        [self finishedDecklist:NO decks:nil];
    }];
    [operation start];
}

-(void) finishedDecklist:(BOOL)ok decks:(NSArray<Deck*>*)decks
{
    if (!ok)
    {
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Loading decks from NetrunnerDB.com failed")
                             buttons:@[l10n(@"OK")]];
    }
    
    self.decklistCompletionBlock(decks);
}

#pragma mark publish deck

-(void) publishDeck:(Deck *)deck completion:(SaveCompletionBlock)completionBlock
{
    self.saveCompletionBlock = completionBlock;
    [self publishDeck:deck];
}

-(void) publishDeck:(Deck *)deck
{
    NSString* publishUrl = [NSString stringWithFormat:@"http://netrunnerdb.com/api_oauth2/publish_deck/%@", deck.netrunnerDbId];
    
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:NRDB_ACCESS_TOKEN];
    NSDictionary* parameters = @{
        @"access_token" : accessToken ? accessToken : @""
    };

    [self saveOrPublish:publishUrl parameters:parameters];
}

#pragma mark load deck

-(void) loadDeck:(Deck *)deck completion:(LoadCompletionBlock)completionBlock
{
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:NRDB_ACCESS_TOKEN];
    if (!accessToken)
    {
        completionBlock(NO, nil);
        return;
    }

    NSAssert(deck.netrunnerDbId, @"no nrdb id");
    NSString* loadUrl = [NSString stringWithFormat:@"http://netrunnerdb.com/api_oauth2/load_deck/%@", deck.netrunnerDbId];
    
    NSDictionary* parameters = @{ @"access_token" : accessToken };
    NSError* error;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                                 URLString:loadUrl
                                                                                parameters:parameters
                                                                                     error:&error];
    // bypass cache!
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        Deck* deck = [self parseDeckFromJson:responseObject];
        completionBlock(YES, deck);
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // NSLog(@"save failed: %@", operation);
        completionBlock(NO, nil);
    }];
    [operation start];
}

-(Deck*) parseDeckFromJson:(NSDictionary*)json
{
    Deck* deck = [[Deck alloc] init];
    
    deck.name = json[@"name"];
    deck.notes = json[@"description"];
    deck.tags = json[@"tags"];
    deck.netrunnerDbId = [NSString stringWithFormat:@"%ld", (long)[json[@"id"] integerValue]];
    
    // parse last update '2014-06-19T13:52:24Z'
    deck.lastModified = [formatter dateFromString:json[@"dateupdate"]];
    deck.dateCreated = [formatter dateFromString:json[@"datecreation"]];
    
    for (NSDictionary* c in json[@"cards"])
    {
        NSString* code = c[@"card_code"];
        NSNumber* qty = c[@"qty"];
        
        Card* card = [CardManager cardByCode:code];
        if (card && qty)
        {
            [deck addCard:card copies:qty.intValue history:NO];
        }
    }
    
    NSArray* history = json[@"history"];
    
    NSMutableArray* revisions = [NSMutableArray array];

    for (NSDictionary* dict in history)
    {
        NSString* datecreation = dict[@"datecreation"];
        // NSLog(@"changeset created: %@", datecreation);
        DeckChangeSet* dcs = [[DeckChangeSet alloc] init];
        dcs.timestamp = [formatter dateFromString:datecreation];
        
        NSArray* variation = dict[@"variation"];
        NSAssert(variation.count == 2, @"wrong variation count");
        // 2-element array: variation[0] contains additions, variation[1] contains deletions
        
        for (int i=0; i<variation.count; ++i)
        {
            NSDictionary* dict = variation[i];
            
            // skip over empty and non-dictionary entries
            if (dict.count == 0) // || ![dict isKindOfClass:[NSDictionary class]])
            {
                continue;
            }
            
            for (NSString* code in [dict allKeys])
            {
                NSNumber* quantity = dict[code];
                NSInteger qty = quantity.integerValue;
                if (i == 1)
                {
                    qty = -qty;
                }
                
                Card* card = [CardManager cardByCode:code];
                
                if (card && qty)
                {
                    [dcs addCardCode:card.code copies:qty];
                }
            }
        }
        [dcs sort];
        [revisions addObject:dcs];
    }
    
    DeckChangeSet* initial = [[DeckChangeSet alloc] init];
    initial.initial = YES;
    initial.timestamp = deck.dateCreated;
    [revisions addObject:initial];
    
    deck.revisions = revisions;
    
    DeckChangeSet* newest = deck.revisions[0];
    NSMutableDictionary* cards = [NSMutableDictionary dictionary];
    for (CardCounter* cc in deck.allCards)
    {
        cards[cc.card.code] = @(cc.count);
    }
    newest.cards = [NSMutableDictionary dictionaryWithDictionary:cards];
    
    // walk through the deck's history and pre-compute a card list for every revision
    for (int i = 0; i < deck.revisions.count-1; ++i)
    {
        DeckChangeSet* prev = deck.revisions[i];
        for (DeckChange* dc in prev.changes)
        {
            NSNumber* qty = cards[dc.code];
            qty = @(qty.integerValue - dc.count);
            if (qty.integerValue == 0)
            {
                [cards removeObjectForKey:dc.code];
            }
            else
            {
                cards[dc.code] = qty;
            }
        }
        DeckChangeSet* dcs = deck.revisions[i+1];
        dcs.cards = [NSMutableDictionary dictionaryWithDictionary:cards];
    }
    
    /*
    for (int i=0; i < deck.revisions.count; ++i)
    {
        DeckChangeSet* dcs = deck.revisions[i];
        NSLog(@"%d %@", i, dcs.cards);
    }
    */
    
    return deck;
}

#pragma mark save deck

-(void) saveDeck:(Deck*)deck completion:(SaveCompletionBlock)completionBlock
{
    self.saveCompletionBlock = completionBlock;
    
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:NRDB_ACCESS_TOKEN];
    if (accessToken)
    {
        [self saveDeck:deck];
    }
    else
    {
        completionBlock(NO, nil);
    }
}

-(void) saveDeck:(Deck *)deck
{
    NSMutableArray* json = [NSMutableArray array];
    if (deck.identity)
    {
        [json addObject:@{ @"card_code": deck.identity.code, @"qty": @1 }];
    }
    for (CardCounter* cc in deck.cards)
    {
        [json addObject:@{ @"card_code": cc.card.code, @"qty": @(cc.count) }];
    }
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSString* deckId = @"0";
    if (deck.netrunnerDbId)
    {
        deckId = deck.netrunnerDbId;
    }
    NSString* saveUrl = [NSString stringWithFormat:@"http://netrunnerdb.com/api_oauth2/save_deck/%@", deckId];
    
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:NRDB_ACCESS_TOKEN];
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"access_token"] = accessToken ? accessToken : @"";
    parameters[@"content"] = jsonStr;
    if (deck.name)
    {
        parameters[@"name"] = deck.name;
    }
    if (deck.notes)
    {
        parameters[@"description"] = deck.notes;
    }
    if (deck.netrunnerDbId)
    {
        parameters[@"id"] = deck.netrunnerDbId;
    }
    if (deck.tags.count > 0)
    {
        parameters[@"tags"] = [deck.tags componentsJoinedByString:@" "];
    }
    
    [self saveOrPublish:saveUrl parameters:parameters];
}

-(void) saveOrPublish:(NSString*)url parameters:(NSDictionary*)parameters
{
    NSError* error;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                                 URLString:url
                                                                                parameters:parameters
                                                                                     error:&error];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        BOOL success = [responseObject[@"success"] boolValue];
        if (success)
        {
            id idFromJson = responseObject[@"message"][@"id"];
            
            NSString* deckId;
            if ([idFromJson isKindOfClass:[NSString class]])
            {
                deckId = idFromJson;
            }
            else if ([idFromJson isKindOfClass:[NSNumber class]])
            {
                deckId = ((NSNumber*)idFromJson).stringValue;
            }
            if (deckId)
            {
                self.saveCompletionBlock(YES, deckId);
            }
            else
            {
                self.saveCompletionBlock(NO, nil);
            }
        }
        else
        {
            self.saveCompletionBlock(NO, nil);
        }
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(self);
        // NSLog(@"save failed: %@", operation);
        self.saveCompletionBlock(NO, nil);
    }];
    [operation start];
}

#pragma mark deck map

-(void) updateDeckMap:(NSArray<Deck*>*)decks
{
    self.deckMap = [NSMutableDictionary dictionary];
    for (Deck* deck in decks)
    {
        if (deck.netrunnerDbId)
        {
            [self.deckMap setObject:deck.filename forKey:deck.netrunnerDbId];
        }
    }
}

-(void) deleteDeck:(NSString*) deckId
{
    if (deckId)
    {
        [self.deckMap removeObjectForKey:deckId];
    }
}

-(NSString*) filenameForId:(NSString*)deckId
{
    return [self.deckMap objectForKey:deckId];
}

@end
