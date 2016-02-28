//
//  OctgnImport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 19.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class OctgnImport: NSObject, NSXMLParserDelegate {
    
    var parser: NSXMLParser!
    var deck: Deck!
    var notes: String?
    
    func parseOctgnDeckFromData(data: NSData) -> Deck? {
        self.parser = NSXMLParser(data: data)
        self.parser.delegate = self
        
        self.deck = Deck()
        
        let ok = self.parser.parse()
        if ok && self.deck.role != .None {
            return self.deck
        } else {
            return nil
        }
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        self.notes = nil
        
        if elementName == "card" {
            if let qty = attributeDict["qty"], id = attributeDict["id"] {
            
                if id.hasPrefix(OCTGN_CODE_PREFIX) && id.length > 32 {

                    let code = (id as NSString).substringFromIndex(31)
                    let card = CardManager.cardByCode(code)
                    let copies = Int(qty)
                    
                    if card != nil && copies != nil {
                        // NSLog(@"card: %d %@", copies, card.name);
                        self.deck.addCard(card!, copies:copies!)
                        self.deck.role = card!.role
                    }
                }
            }

        } else if elementName == "notes" {
            self.notes = ""
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "notes" {
            self.deck.notes = self.notes
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if self.notes != nil {
            self.notes! += string
        }
    }
}