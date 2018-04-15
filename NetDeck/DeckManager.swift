//
//  DeckManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 05.12.15.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

class DeckManager {
    
    static let cache: NSCache<NSString, Deck> = {
        let c = NSCache<NSString, Deck>()
        c.name = "deckCache"
        return c
    }()
    
    static func saveDeck(_ deck: Deck, keepLastModified: Bool) {
        if deck.filename == nil {
            deck.filename = DeckManager.pathForRole(deck.role)
        }
        
        let filename = deck.filename!
        // print("save \(deck.name) to disk")
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        
        encoder.encode(deck, forKey: "deck")
        encoder.finishEncoding()
        
        let saveOk = data.write(toFile: filename, atomically: true)
        if !saveOk {
            DeckManager.removeFile(filename)
            return
        }
        
        let fileMgr = FileManager.default
        if let date = deck.dateCreated {
            let attrs = [ FileAttributeKey.creationDate: date ]
            
            _ = try? fileMgr.setAttributes(attrs, ofItemAtPath: filename)
        }
        
        if keepLastModified && deck.lastModified != nil {
            let attrs = [ FileAttributeKey.modificationDate: deck.lastModified! ]
            _ = try? FileManager.default.setAttributes(attrs, ofItemAtPath: deck.filename!)
        } else {
            // update the in-memory lastModified date
            deck.lastModified = Date()
        }

        // store the deck in our cache
        DeckManager.cache.setObject(deck, forKey: filename as NSString)
    }
    
    static func removeFile(_ pathname: String) {
        DeckManager.cache.removeObject(forKey: pathname as NSString)
        _ = try? FileManager.default.removeItem(atPath: pathname)
    }
    
    static func decksForRole(_ role: Role) -> [Deck] {
        if role == .none {
            var decks = [Deck]()
            decks.append(contentsOf: loadDecksForRole(.runner))
            decks.append(contentsOf: loadDecksForRole(.corp))
            return decks
        }
        return loadDecksForRole(role)
    }
    
    private static func loadDecksForRole(_ role: Role) -> [Deck] {
        var decks = [Deck]()
        
        let dir = directoryForRole(role)
        if let dirContents = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            for file in dirContents {
                let path = dir.appendPathComponent(file)
                if let deck = loadDeckFromPath(path) {
                    decks.append(deck)
                }
            }
        }
        return decks
    }
    
    static func loadDeckFromPath(_ path: String, useCache: Bool = true) -> Deck? {
        if useCache {
            if let cachedDeck = DeckManager.cache.object(forKey: path as NSString) {
                return cachedDeck
            }
        }
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            let decoder = NSKeyedUnarchiver(forReadingWith: data)
            if let deck = decoder.decodeObject(forKey: "deck") as? Deck {
                deck.filename = path

                if let attrs = try? FileManager.default.attributesOfItem(atPath: path) {
                    deck.lastModified = attrs[FileAttributeKey.modificationDate] as? Date
                    deck.dateCreated = attrs[FileAttributeKey.creationDate] as? Date
                }

                DeckManager.cache.setObject(deck, forKey: path as NSString)
                return deck
            }
        }
        return nil
    }
    
    static func numberOfDecks() -> Int {
        let roles = [Role.runner, .corp]
        
        let decks = roles.reduce(0) {
            let dir = directoryForRole($1)
            let files = try? FileManager.default.contentsOfDirectory(atPath: dir)
            return $0 + (files?.count ?? 0)
        }
        
        return decks
    }
    
    static func directoryForRole(_ role: Role) -> String {
        assert(role != .none, "wrong role")
        
        let roleDir = role == .runner ? "runnerDecks" : "corpDecks"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let dir = paths[0].appendPathComponent(roleDir)
        
        let fileMgr = FileManager.default
        if !fileMgr.fileExists(atPath: dir) {
            _ = try? fileMgr.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    
    static func pathForRole(_ role: Role) -> String {
        let dir = directoryForRole(role)
        let file = String(format:"deck-%d.anr", nextFileSequence())
        let path = dir.appendPathComponent(file)
        
        return path
    }
    
    static func fileSequence() -> Int {
        return Defaults[.fileSequence]
    }
    
    private static func nextFileSequence() -> Int {
        let seq = Defaults[.fileSequence]
        Defaults[.fileSequence] += 1
        return seq
    }
    
    static func flushCache() {
        DeckManager.cache.removeAllObjects()
    }
}
