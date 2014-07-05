//
//  NRDB.m
//  NRDB
//
//  Created by Gereon Steffens on 20.06.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <AFNetworking.h>
#import <SVProgressHUD.h>
#import <EXTScope.h>
#import <SDCAlertView.h>

#import "NRDB.h"
#import "NRDBAuth.h"
#import "SettingsKeys.h"
#import "Deck.h"

@interface NRDB()
@property (strong) DecklistCompletionBlock decklistCompletionBlock;
@property (strong) SaveCompletionBlock saveCompletionBlock;
@property NSTimer* timer;
@end

@implementation NRDB

#define REFRESH_INTERVAL    3300 // 55 minutes

static NRDB* instance;
+(NRDB*) sharedInstance
{
    if (!instance)
    {
        instance = [[NRDB alloc] init];
    }
    return instance;
}

#pragma mark autorization

-(void) authorizeWithCode:(NSString *)code completion:(AuthCompletionBlock)completionBlock
{
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
    // ?client_id=" CLIENT_ID "&client_secret=" CLIENT_SECRET "&grant_type=refresh_token&redirect_uri=" CLIENT_HOST "&refresh_token="
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"client_id"] = @CLIENT_ID;
    parameters[@"client_secret"] = @CLIENT_SECRET;
    parameters[@"grant_type"] = @"refresh_token";
    parameters[@"redirect_uri"] = @CLIENT_HOST;
    parameters[@"refresh_token"] = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_REFRESH_TOKEN];

    [self getAuthorization:parameters completion:completionBlock];
}

-(void) getAuthorization:(NSDictionary*)parameters completion:(AuthCompletionBlock)completionBlock
{
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:@AUTH_URL parameters:parameters
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
             NSDate* expiry = [[NSDate date] dateByAddingTimeInterval:[exp intValue]];
             [settings setObject:expiry forKey:NRDB_TOKEN_EXPIRY];
             
             if (!ok)
             {
                 [settings removeObjectForKey:NRDB_REFRESH_TOKEN];
                 [settings removeObjectForKey:NRDB_ACCESS_TOKEN];
                 [settings removeObjectForKey:NRDB_TOKEN_EXPIRY];
             }
             [settings synchronize];
             
             completionBlock(ok);
         }
         failure:^(AFHTTPRequestOperation* operation, NSError* error) {
             NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
             [settings removeObjectForKey:NRDB_ACCESS_TOKEN];
             [settings removeObjectForKey:NRDB_REFRESH_TOKEN];
             [settings removeObjectForKey:NRDB_TOKEN_EXPIRY];
             [settings setObject:@(NO) forKey:USE_NRDB];
             [settings synchronize];
             
             completionBlock(NO);
         }
    ];
}

-(void) refreshAuthentication
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    if (![settings boolForKey:USE_NRDB])
    {
        return;
    }
    
    NSDate* expiry = [settings objectForKey:NRDB_TOKEN_EXPIRY];
    NSDate* now = [NSDate date];
    NSTimeInterval diff = [expiry timeIntervalSinceDate:now];
    diff -= 5*60; // 5 minutes overlap
    
    if (diff < 0)
    {
        // token is expired, refresh now
        [self refreshToken:^(BOOL ok) {
            if (ok)
            {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_INTERVAL
                                                              target:self
                                                            selector:@selector(refreshTimerFire:)
                                                            userInfo:nil
                                                             repeats:YES];
            }
        }];
    }
    else
    {
        // token still valid, schedule refresh
    }
}

-(void) refreshTimerFire:(NSTimer*)timer
{
    [self refreshToken:^(BOOL ok) {
    }];
}

#pragma mark deck list

-(void) decklist:(DecklistCompletionBlock)completionBlock
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Loading decks..")];
    self.decklistCompletionBlock = completionBlock;
    [self performSelector:@selector(getDecks) withObject:nil afterDelay:0.01];
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    if (!ok)
    {
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Loading decks from NetrunnerDB.com failed")
                             buttons:@[l10n(@"OK")]];
        
    }
    
    self.decklistCompletionBlock(decks);
}

#pragma mark save deck

-(void) saveDeck:(Deck*)deck completion:(SaveCompletionBlock)completionBlock
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Saving Deck...")];
    self.saveCompletionBlock = completionBlock;
    [self performSelector:@selector(saveDeck:) withObject:deck afterDelay:0.01];
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
    
    NSError* error;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                                 URLString:saveUrl
                                                                                parameters:parameters
                                                                                     error:&error];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        // NSLog(@"save ok: %@", responseObject);
        NSString* deckId = responseObject[@"message"][@"id"];
        [self finishedSave:YES deckId:deckId];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(self);
        // NSLog(@"save failed: %@", operation);
        [self finishedSave:NO deckId:nil];
    }];
    [operation start];
}

-(void) finishedSave:(BOOL)ok deckId:(NSString*)deckId
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    self.saveCompletionBlock(ok, deckId);
}

@end
