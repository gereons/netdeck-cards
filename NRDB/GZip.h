//
//  GZip.h
//  NRDB
//
//  Created by Gereon Steffens on 28.07.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface GZip : NSObject

+(NSData *)gzipInflate:(NSData*)data;
+(NSData *)gzipDeflate:(NSData*)data;

@end
