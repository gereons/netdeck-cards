//
//  TableData.h
//  Net Deck
//
//  Created by Gereon Steffens on 13.01.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface TableData : NSObject

@property NSArray* sections;
@property NSArray* values;
@property NSMutableArray* collapsedSections;

-(id) initWithValues:(NSArray*)values;
-(id) initWithSections:(NSArray*)sections andValues:(NSArray*)values;

@end
