//
//  GZip.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.07.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface GZip : NSObject

+(NSData *)gzipInflate:(NSData*)data;
+(NSData *)gzipDeflate:(NSData*)data;

@end
