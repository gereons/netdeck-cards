//
//  OctgnImport.h
//  Net Deck
//
//  Created by Gereon Steffens on 16.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface OctgnImport : NSObject <NSXMLParserDelegate>

-(Deck*) parseOctgnDeckFromData:(NSData*)data;
-(Deck*) parseOctgnDeckWithParser:(NSXMLParser*)parser;

@end
