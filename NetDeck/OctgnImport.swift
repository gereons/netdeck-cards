//
//  OctgnImport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 19.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class OctgnImport: NSObject, XMLParserDelegate {
    
    var parser: XMLParser!
    var deck: Deck!
    var notes: String?
    
    func parseOctgnDeckFromData(_ data: Data) -> Deck? {
        self.parser = XMLParser(data: data)
        self.parser.delegate = self
        
        self.deck = Deck()
        
        let ok = self.parser.parse()
        if ok && self.deck.role != .none {
            return self.deck
        } else {
            return nil
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        
        self.notes = nil
        
        if elementName == "card" {
            if let qty = attributeDict["qty"], let id = attributeDict["id"] {
            
                if id.hasPrefix(Card.OCTGN_PREFIX) && id.length > 32 {

                    let code = (id as NSString).substring(from: 31)
                    let card = CardManager.cardByCode(code)
                    let copies = Int(qty)
                    
                    if card != nil && copies != nil {
                        // NSLog(@"card: %d %@", copies, card.name);
                        self.deck.addCard(card!, copies: copies!)
                        self.deck.role = card!.role
                    }
                }
            }

        } else if elementName == "notes" {
            self.notes = ""
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "notes" {
            self.deck.notes = self.notes
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.notes != nil {
            self.notes! += string
        }
    }
}
