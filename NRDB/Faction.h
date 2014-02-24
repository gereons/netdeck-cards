//
//  Faction.h
//  NRDB
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Faction : NSObject

+(NSString*) name:(NRFaction)faction;
+(NRFaction) faction:(NSString*)code;

+(NSArray*) factionsForRole:(NRRole)role;

@end
