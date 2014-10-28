//
//  UIAlertAction+cancel.h
//  NRDB
//
//  Created by Gereon Steffens on 28.10.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@interface UIAlertAction(NRDB)

+(UIAlertAction*) cancelAction:(void (^)(UIAlertAction *action))handler;
+(UIAlertAction*) actionWithTitle:(NSString*)title handler:(void (^)(UIAlertAction *action))handler;

@end
