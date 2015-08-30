//
//  FilterCallback.h
//  Net Deck
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@protocol FilterCallback <NSObject>

-(void) filterCallback:(UIButton*)button type:(NSString*)type value:(NSObject*)value;

@end
