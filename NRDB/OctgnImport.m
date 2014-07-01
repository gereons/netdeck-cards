//
//  OctgnImport.m
//  NRDB
//
//  Created by Gereon Steffens on 16.04.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "OctgnImport.h"
#import "Deck.h"
@interface OctgnImport()

@property NSXMLParser* parser;
@property BOOL setIdentity;
@property Deck* deck;
@property NSMutableString* notes;

@end

@implementation OctgnImport

-(Deck*) parseOctgnDeckFromData:(NSData *)data
{
    self.parser = [[NSXMLParser alloc] initWithData:data];
    self.parser.delegate = self;

    return [self parse];
}

-(Deck*) parseOctgnDeckWithParser:(NSXMLParser *)parser
{
    self.parser = parser;
    self.parser.delegate = self;
    
    return [self parse];
}

-(Deck*) parse
{
    self.deck = [[Deck alloc] init];
    
    if ([self.parser parse])
    {
        return self.deck;
    }
    else
    {
        return nil;
    }
}

-(void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.notes = nil;
    
    if ([elementName isEqualToString:@"section"])
    {
        NSString* name = attributeDict[@"name"];
        self.setIdentity = [[name lowercaseString] isEqualToString:@"identity"];
        // NSLog(@"start section: %@", name);
    }
    
    if ([elementName isEqualToString:@"card"])
    {
        NSString* qty = attributeDict[@"qty"];
        NSString* code = attributeDict[@"id"];
        
        Card* card = [Card cardByCode:[code substringFromIndex:31]];
        int copies = [qty intValue];
        
        // NSLog(@"card: %d %@", copies, card.name);
        if (self.setIdentity)
        {
            self.deck.identity = card;
        }
        else
        {
            [self.deck addCard:card copies:copies];
        }
    }
    
    if ([elementName isEqualToString:@"notes"])
    {
        self.notes = [NSMutableString string];
    }
}

-(void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"notes"])
    {
        self.deck.notes = self.notes;
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.notes appendString:string];
}

@end
