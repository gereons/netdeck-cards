//
//  UIAlertAction+cancel.m
//  NRDB
//
//  Created by Gereon Steffens on 28.10.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "UIAlertAction+NRDB.h"

@implementation UIAlertAction (NRDB)

+(UIAlertAction*) cancelAction:(void (^)(UIAlertAction *action))handler
{
    return [UIAlertAction actionWithTitle:@"" style:UIAlertActionStyleCancel handler:handler];
}

+(UIAlertAction*) actionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler
{
    return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:handler];
}

@end