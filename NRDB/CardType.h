//
//  CardType.h
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardType : NSObject

+(NRCardType) type:(NSString*)code;
+(NSString*) name:(NRCardType)type;

+(NSArray*) typesForRole:(NRRole)role;
+(NSArray*) subtypesForRole:(NRRole)role andType:(NSString*)type;

@end
