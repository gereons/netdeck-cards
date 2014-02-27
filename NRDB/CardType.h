//
//  CardType.h
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardType : NSObject

+(NRCardType) type:(NSString*)code;
+(NSString*) name:(NRCardType)type;

+(NSArray*) typesForRole:(NRRole)role;
+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type;
+(NSArray*) subtypesForRole:(NRRole)role andTypes:(NSSet*)types;

+(void) initializeCardTypes:(NSDictionary*)cards;

@end
