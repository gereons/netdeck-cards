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
#import "SettingsKeys.h"

@interface NRDB()
@property (strong) LoginCompletionBlock loginCompletionBlock;
@property (strong) DecklistCompletionBlock decklistCompletionBlock;
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

-(void) login:(LoginCompletionBlock)completionBlock
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Logging in...")];
    self.loginCompletionBlock = completionBlock;
    self.decklistCompletionBlock = nil;
    [self performSelector:@selector(checkNetrunnerDbLogin) withObject:nil afterDelay:0.01];
}

-(void) decklist:(DecklistCompletionBlock)completionBlock
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:l10n(@"Loading decks..")];
    self.decklistCompletionBlock = completionBlock;
    self.loginCompletionBlock = nil;
    [self performSelector:@selector(getDecks) withObject:nil afterDelay:0.01];
}

-(void) checkNetrunnerDbLogin
{
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    NSString* user = [settings objectForKey:NRDB_USERNAME];
    NSString* pass = [settings objectForKey:NRDB_PASSWORD];
    
    if (user.length == 0 || pass.length == 0)
    {
        [SVProgressHUD dismiss];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Please enter username and password for your netrunnerdb.com account")
                             buttons:@[l10n(@"OK")]];
        return;
    }
    
    // remove old REMEMBERME cookie
    NSHTTPCookieStorage* jar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie* cookie in [jar cookies])
    {
        [jar deleteCookie:cookie];
    }
    
    // fake a PHPSESSID cookie
    NSHTTPCookie* cookie = [self nrdbCookie:@"PHPSESSID" value:@"dontcare"];
    NSDictionary *cookies = [NSHTTPCookie requestHeaderFieldsWithCookies:@[ cookie ]];
    
    NSError* error;
    NSString* loginUrl = @"http://netrunnerdb.com/login_check";
    NSDictionary* parameters = @{
                                 @"_username": user,
                                 @"_password": pass,
                                 @"_remember_me": @"on",
                                 @"_csrf_token": @"",
                                 @"_submit": @"Login",
                                 };
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST"
                                                                                 URLString:loginUrl
                                                                                parameters:parameters
                                                                                     error:&error];
    [request setAllHTTPHeaderFields:cookies];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        NSString* rememberme;
        for (NSHTTPCookie* cookie in [jar cookies])
        {
            if ([cookie.name isEqualToString:@"REMEMBERME"])
            {
                rememberme = cookie.value;
                break;
            }
        }
        
        if (rememberme)
        {
            [settings setObject:rememberme forKey:NRDB_REMEMBERME];
            [self getDecks];
        }
        else
        {
            [self finished:NO decks:nil];
        }
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self finished:NO decks:nil];
    }];
    [operation start];
}

-(void) getDecks
{
    NSString* decksUrl = @"http://netrunnerdb.com/api/decks";
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    NSHTTPCookie* cookie = [self nrdbCookie:@"REMEMBERME" value:[settings objectForKey:NRDB_REMEMBERME]];
    NSDictionary *cookies = [NSHTTPCookie requestHeaderFieldsWithCookies:@[ cookie ]];
    
    NSError* error;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
                                                                                 URLString:decksUrl
                                                                                parameters:nil
                                                                                     error:&error];
    [request setAllHTTPHeaderFields:cookies];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        [self finished:YES decks:responseObject];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(self);
        [self finished:NO decks:nil];
    }];
    [operation start];
}

-(void) finished:(BOOL)ok decks:(NSArray*)decks
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    if (!ok)
    {
        [SDCAlertView alertWithTitle:nil
                             message:l10n(@"Login at netrunnerdb.com failed")
                             buttons:@[l10n(@"OK")]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:NRDB_REMEMBERME];
    }
    
    if (self.decklistCompletionBlock)
    {
        self.decklistCompletionBlock(decks);
    }
    else if (self.loginCompletionBlock)
    {
        self.loginCompletionBlock(ok);
    }
}

-(NSHTTPCookie*) nrdbCookie:(NSString*)name value:(NSString*)value
{
    NSDictionary *properties = @{
                                 NSHTTPCookiePath: @"/",
                                 NSHTTPCookieDomain: @"netrunnerdb.com",
                                 NSHTTPCookieName: name,
                                 NSHTTPCookieValue: value,
                                 };
    return [NSHTTPCookie cookieWithProperties:properties];
}

@end
