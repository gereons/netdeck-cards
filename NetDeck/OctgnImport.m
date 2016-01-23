//
//  OctgnImport.m
//  Net Deck
//
//  Created by Gereon Steffens on 16.04.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "OctgnImport.h"

@interface OctgnImport()

@property NSXMLParser* parser;
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
    
    if ([self.parser parse] && self.deck.role != NRRoleNone)
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
    
    if ([elementName isEqualToString:@"card"])
    {
        NSString* qty = attributeDict[@"qty"];
        NSString* code = attributeDict[@"id"];
        
        if ([code hasPrefix:OCTGN_CODE_PREFIX] && code.length > 32)
        {
            Card* card = [CardManager cardByCode:[code substringFromIndex:31]];
            int copies = [qty intValue];
        
            if (card)
            {
                // NSLog(@"card: %d %@", copies, card.name);
                [self.deck addCard:card copies:copies];
                self.deck.role = card.role;
            }
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
