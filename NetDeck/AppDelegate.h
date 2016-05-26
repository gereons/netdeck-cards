//
//  AppDelegate.h
//  Net Deck
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"
#import "NRCrashlytics.h"

@interface xAppDelegate : UIResponder <UIApplicationDelegate CRASHLYTICS_DELEGATE>

@property (strong, nonatomic) UIWindow *window;

// root controller on ipad
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet DetailViewManager *detailViewManager;

// root controller on iphone
@property (nonatomic, retain) IBOutlet UINavigationController* navigationController;

+(NSString*) appVersion;

// utility method: set the excludeFromBackup flag on the specified path
+(void) excludeFromBackup:(NSString*)path;

@end
