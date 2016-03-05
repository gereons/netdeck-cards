//
//  DataDownload.h
//  Net Deck
//
//  Created by Gereon Steffens on 24.02.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface xDataDownload : NSObject

+(void) downloadCardData;       // blocks UI, posts LOAD_CARDS notification when done
+(void) downloadAllImages;      // blocks UI, returns when download is done
+(void) downloadMissingImages;  // blocks UI, returns when download is done

@end
