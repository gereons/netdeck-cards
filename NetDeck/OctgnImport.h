//
//  OctgnImport.h
//  Net Deck
//
//  Created by Gereon Steffens on 16.04.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface OctgnImport : NSObject <NSXMLParserDelegate>

-(Deck*) parseOctgnDeckFromData:(NSData*)data;
-(Deck*) parseOctgnDeckWithParser:(NSXMLParser*)parser;

@end
