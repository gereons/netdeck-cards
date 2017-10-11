//
//  OctgnImport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 19.02.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

class OctgnImport: NSObject, XMLParserDelegate {
    
    private let deck = Deck(role: .none)
    private var notes: String?
    
    func parseOctgnDeckFromData(_ data: Data) -> Deck? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        let ok = parser.parse()
        if ok && self.deck.role != .none {
            return self.deck
        } else {
            return nil
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        if elementName == "card" {
            if let qty = attributeDict["qty"], let id = attributeDict["id"] {
                if id.hasPrefix(Card.octgnPrefix) && id.count > 32 {
                    let index = id.index(id.startIndex, offsetBy: 31)
                    let cardCode = String(id[index...])

                    let code: String = {
                        if Defaults[.defaultMWL] == .v2_0 {
                            return Card.originalToRevised[cardCode] ?? cardCode
                        } else {
                            return cardCode
                        }
                    }()

                    if let card = CardManager.cardBy(code: code), let copies = Int(qty) {
                        // NSLog(@"card: %d %@", copies, card.name);
                        self.deck.addCard(card, copies: copies)
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
