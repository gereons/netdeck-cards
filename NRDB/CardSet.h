//
//  CardSet.h
//  NRDB
//
//  Created by Gereon Steffens on 13.02.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardSet : NSObject

@property NSString* name;
@property int setNum;
@property NSString* setCode;
@property NSString* settingsKey;
@property NRCycle cycle;
@property BOOL released;

@end
