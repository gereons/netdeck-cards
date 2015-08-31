//
//  Faction.h
//  Net Deck
//
//  Created by Gereon Steffens on 15.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class TableData;
@interface Faction : NSObject

+(NSString*) name:(NRFaction)faction;
+(NSString*) shortName:(NRFaction)faction;
+(NRFaction) faction:(NSString*)code;

+(NSArray*) factionsForRole:(NRRole)role;
+(TableData*) allFactions;

+(void) initializeFactionNames:(NSArray*)cards;

@end
