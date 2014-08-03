//
//  FilterCallback.h
//  NRDB
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FilterCallback <NSObject>

-(void) filterCallback:(UIButton*)button value:(NSObject*)value;

@end
