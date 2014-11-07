//
//  NRDB.m
//  NRDB
//
//  Created by Gereon Steffens on 20.06.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <EXTScope.h>
#import <SDCAlertView.h>

#import "NRDB.h"
#import "NRDBAuth.h"
#import "SettingsKeys.h"
#import "Deck.h"

@interface NRDB()
@property (strong) DecklistCompletionBlock decklistCompletionBlock;
@property (strong) SaveCompletionBlock saveCompletionBlock;
@property NSMutableDictionary* deckMap;
@property NSTimer* timer;
@end

@implementation NRDB

static NRDB* instance;

+(NRDB*) sharedInstance
{
    if (!instance)
    {
        instance = [[NRDB alloc] init];
    }
    return instance;
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
}

#pragma mark autorization

-(void) authorizeWithCode:(NSString *)code completion:(AuthCompletionBlock)completionBlock
{
    // NSLog(@"auth code");
    // ?client_id=" CLIENT_ID "&client_secret=" CLIENT_SECRET "&grant_type=authorization_code&redirect_uri=" CLIENT_HOST "&code="
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"client_id"] = @CLIENT_ID;
    parameters[@"client_secret"] = @CLIENT_SECRET;
    parameters[@"grant_type"] = @"authorization_code";
    parameters[@"redirect_uri"] = @CLIENT_HOST;
    parameters[@"code"] = code;
    
    [self getAuthorization:parameters completion:completionBlock];
}

-(void) refreshToken:(AuthCompletionBlock)completionBlock
{
    // NSLog(@"refresh token");
    // ?client_id=" CLIENT_ID "&client_secret=" CLIENT_SECRET "&grant_type=refresh_token&redirect_uri=" CLIENT_HOST "&refresh_token="

    NSString* token = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_REFRESH_TOKEN];
    
    if (token == nil)
    {
        completionBlock(NO);
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"client_id"] = @CLIENT_ID;
    parameters[@"client_secret"] = @CLIENT_SECRET;
    parameters[@"grant_type"] = @"refresh_token";
    parameters[@"redirect_uri"] = @CLIENT_HOST;
    parameters[@"refresh_token"] = token;

    [self getAuthorization:parameters completion:completionBlock];
}

-(void) getAuthorization:(NSDictionary*)parameters completion:(AuthCompletionBlock)completionBlock
{
    if (!APP_ONLINE)
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
             completionBlock(ok);
         }
         failure:^(AFHTTPRequestOperation* operation, NSError* error) {
             [NRDB clearSettings];
             
             NSLog(@"nrdb (re)auth failed: %@", operation);
             [SDCAlertView alertWithTitle:nil
                                  message:l10n(@"Authorization at NetrunnerDB.com failed")
                                  buttons:@[ l10n(@"OK") ]];
             
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
    
    NSError* error;
    NSDictionary* params = @{
        @"access_token" : [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_ACCESS_TOKEN]
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

-(void) finishedDecklist:(BOOL)ok decks:(NSArray*)decks
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
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"access_token"] = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_ACCESS_TOKEN];
    
    [self saveOrPublish:publishUrl parameters:parameters];
}

#pragma mark save deck

-(void) saveDeck:(Deck*)deck completion:(SaveCompletionBlock)completionBlock
{
    self.saveCompletionBlock = completionBlock;
    
    NSString* token = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_ACCESS_TOKEN];
    if (token)
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
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"access_token"] = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_ACCESS_TOKEN];
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
            NSString* deckId = responseObject[@"message"][@"id"];
            self.saveCompletionBlock(YES, deckId);
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

-(void) updateDeckMap:(NSArray *)decks
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
