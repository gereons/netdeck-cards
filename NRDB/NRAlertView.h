//
//  NRAlertView.h
//  NRDB
//
//  Created by Gereon Steffens on 03.09.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NRAlertView : UIAlertView <UIAlertViewDelegate>

typedef void (^NRAlertViewBlock)(NSInteger buttonIndex);

- (void) showWithDismissHandler:(NRAlertViewBlock)action;

@end
