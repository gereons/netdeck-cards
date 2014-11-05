//
//  AppDelegate.h
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"
#import "NRSplitViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) IBOutlet NRSplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet DetailViewManager *detailViewManager;

+(NSString*) appVersion;

@end
