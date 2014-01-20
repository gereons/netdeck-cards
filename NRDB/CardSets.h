//
//  CardSets.h
//  NRDB
//
//  Created by Gereon Steffens on 14.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TableData.h"

@interface CardSets : NSObject

+(NSArray*) allSets;
+(TableData*) allSetsForTableview;

+(NSDictionary*) settingsDefaults;
+(NSSet*) disabledSetCodes;

@end
