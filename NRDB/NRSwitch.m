//
//  NRSwitch.m
//  NRDB
//
//  Created by Gereon Steffens on 24.09.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "NRSwitch.h"

@interface NRSwitch()
@property (nonatomic, copy) NRSwitchBlock block;
@end

@implementation NRSwitch

-(instancetype) initWithHandler:(NRSwitchBlock)block
{
    if ((self = [super init]))
    {
        self.block = block;
        [self addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

-(void) toggleSwitch:(UISwitch*)sender
{
    self.block(sender.on);
}

@end
