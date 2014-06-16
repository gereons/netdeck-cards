//
//  DataDownload.h
//  NRDB
//
//  Created by Gereon Steffens on 24.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SDCAlertView.h>

@interface DataDownload : NSObject<SDCAlertViewDelegate>

+(void) downloadCardData;       // blocks UI, posts LOAD_CARDS notification when done
+(void) downloadAllImages;      // blocks UI, returns when download is done
+(void) downloadMissingImages;  // blocks UI, returns when download is done

@end
