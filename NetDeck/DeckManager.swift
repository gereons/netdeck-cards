//
//  DeckManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 05.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class DeckManager: NSObject {
    
    static let cache = { () -> NSCache<NSString, Deck> in
        let c = NSCache<NSString, Deck>()
        c.name = "deckCache"
        return c
    }()
    
    class func saveDeck(_ deck: Deck, keepLastModified: Bool) {
        if deck.filename == nil {
            deck.filename = DeckManager.pathForRole(deck.role)
        }
        
        let filename = deck.filename!
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
    
    class func removeFile(_ pathname: String) {
        DeckManager.cache.removeObject(forKey: pathname as NSString)
        _ = try? FileManager.default.removeItem(atPath: pathname)
    }
    
    class func decksForRole(_ role: NRRole) -> [Deck] {
        if role == .none {
            var decks = [Deck]()
            decks.append(contentsOf: loadDecksForRole(.runner))
            decks.append(contentsOf: loadDecksForRole(.corp))
            return decks
        }
        return loadDecksForRole(role)
    }
    
    class func loadDecksForRole(_ role: NRRole) -> [Deck] {
        var decks = [Deck]()
        
        let dir = directoryForRole(role)
        let dirContents = try? FileManager.default.contentsOfDirectory(atPath: dir)
        if dirContents == nil {
            return decks
        }
        
        for file in dirContents! {
            let path = dir.stringByAppendingPathComponent(file)
            if let deck = loadDeckFromPath(path) {
                decks.append(deck)
            }
        }

        return decks
    }
    
    class func loadDeckFromPath(_ path: String) -> Deck? {
        return loadDeckFromPath(path, useCache: true)
    }
    
    class func loadDeckFromPath(_ path: String, useCache: Bool) -> Deck? {
        if useCache {
            if let cachedDeck = DeckManager.cache.object(forKey: path as NSString) {
                return cachedDeck
            }
        }
        
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        if data == nil {
            return nil
        }
        
        let decoder = NSKeyedUnarchiver(forReadingWith: data!)
        if let deck = decoder.decodeObject(forKey: "deck") as? Deck {
            deck.filename = path
            
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path) {
                deck.lastModified = attrs[FileAttributeKey.modificationDate] as? Date
                deck.dateCreated = attrs[FileAttributeKey.creationDate] as? Date
            }
            
            DeckManager.cache.setObject(deck, forKey: path as NSString)
            return deck
        }
        return nil
    }
    
    class func directoryForRole(_ role: NRRole) -> String {
        assert(role != .none, "wrong role")
        
        let roleDir = role == .runner ? "runnerDecks" : "corpDecks"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let dir = paths[0].stringByAppendingPathComponent(roleDir)
        
        let fileMgr = FileManager.default
        if !fileMgr.fileExists(atPath: dir) {
            _ = try? fileMgr.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    
    class func pathForRole(_ role: NRRole) -> String {
        let dir = directoryForRole(role)
        let file = String(format:"deck-%d.anr", nextFileId())
        let path = dir.stringByAppendingPathComponent(file)
        
        return path
    }
    
    class func nextFileId() -> Int {
        let settings = UserDefaults.standard
        let fileId = settings.integer(forKey: SettingsKeys.FILE_SEQ)
        settings.set(fileId+1, forKey: SettingsKeys.FILE_SEQ)
        return fileId
    }
    
    class func flushCache() {
        DeckManager.cache.removeAllObjects()
    }
}
