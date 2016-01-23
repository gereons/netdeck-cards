//
//  NRSwitch.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.09.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface NRSwitch : UISwitch

typedef void (^NRSwitchBlock)(BOOL on);

-(instancetype) initWithHandler:(NRSwitchBlock)block;

@end
