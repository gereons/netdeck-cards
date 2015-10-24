//
//  CardType.h
//  Net Deck
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class TableData;

@interface CardType : NSObject

+(NRCardType) type:(NSString*)code;
+(NSString*) name:(NRCardType)type;

+(NSArray*) typesForRole:(NRRole)role;
+(TableData*) allTypes;

+(void) initializeCardTypes:(NSArray*)cards;

@end
