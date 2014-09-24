//
//  NRSwitch.h
//  NRDB
//
//  Created by Gereon Steffens on 24.09.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NRSwitch : UISwitch

typedef void (^NRSwitchBlock)(BOOL on);

-(instancetype) initWithHandler:(NRSwitchBlock)block;

@end
