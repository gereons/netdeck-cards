//
//  DeckManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 05.12.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class DeckManager: NSObject {
    
    static let cache = { () -> NSCache in
        let c = NSCache()
        c.name = "deckCache"
        return c
    }()
    
    class func saveDeck(deck: Deck) {
        if deck.filename == nil {
            deck.filename = DeckManager.pathForRole(deck.role)
        }
        
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWithMutableData: data)
        
        encoder.encodeObject(deck, forKey: "deck")
        encoder.finishEncoding()
        
        let saveOk = data.writeToFile(deck.filename!, atomically: true)
        if !saveOk {
            DeckManager.removeFile(deck.filename!)
            return
        }
        
        let fileMgr = NSFileManager.defaultManager()
        if let date = deck.dateCreated {
            let attrs = [ NSFileCreationDate: date ]
            
            _ = try? fileMgr.setAttributes(attrs, ofItemAtPath: deck.filename!)
        }
        
        // update the in-memory lastModified date, and store the deck in our cache
        deck.lastModified = NSDate()
        DeckManager.cache.setObject(deck, forKey: deck.filename!)
    }
    
    class func removeFile(pathname: String) {
        DeckManager.cache.removeObjectForKey(pathname)
        _ = try? NSFileManager.defaultManager().removeItemAtPath(pathname)
    }
    
    class func resetModificationDate(deck: Deck) {
        if deck.filename != nil && deck.lastModified != nil {
            let attrs = [ NSFileModificationDate: deck.lastModified! ]
            _ = try? NSFileManager.defaultManager().setAttributes(attrs, ofItemAtPath: deck.filename!)
        }
    }
    
    class func decksForRole(role: NRRole) -> [Deck] {
        if role == .None {
            var decks = [Deck]()
            decks.appendContentsOf(loadDecksForRole(.Runner))
            decks.appendContentsOf(loadDecksForRole(.Corp))
            return decks
        }
        return loadDecksForRole(role)
    }
    
    class func loadDecksForRole(role: NRRole) -> [Deck] {
        var decks = [Deck]()
        
        let dir = directoryForRole(role)
        let dirContents = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(dir)
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
    
    class func loadDeckFromPath(path: String) -> Deck? {
        if let cachedDeck = DeckManager.cache.objectForKey(path) as? Deck {
            return cachedDeck
        }
        
        let data = NSData(contentsOfFile: path)
        if data == nil {
            return nil
        }
        
        let decoder = NSKeyedUnarchiver(forReadingWithData: data!)
        if let deck = decoder.decodeObjectForKey("deck") as? Deck {
            deck.filename = path
            
            if let attrs = try? NSFileManager.defaultManager().attributesOfItemAtPath(path) {
                deck.lastModified = attrs[NSFileModificationDate] as? NSDate
                deck.dateCreated = attrs[NSFileCreationDate] as? NSDate
            }
            
            DeckManager.cache.setObject(deck, forKey: path)
            return deck
        }
        return nil
    }
    
    class func directoryForRole(role: NRRole) -> String {
        assert(role != .None, "wrong role")
        
        let roleDir = role == .Runner ? "runnerDecks" : "corpDecks"
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let dir = paths[0].stringByAppendingPathComponent(roleDir)
        
        let fileMgr = NSFileManager.defaultManager()
        if !fileMgr.fileExistsAtPath(dir) {
            _ = try? fileMgr.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    
    class func pathForRole(role: NRRole) -> String {
        let dir = directoryForRole(role)
        let file = String(format:"deck-%d.anr", nextFileId())
        let path = dir.stringByAppendingPathComponent(file)
        
        return path
    }
    
    class func nextFileId() -> Int {
        let settings = NSUserDefaults.standardUserDefaults()
        let fileId = settings.integerForKey(SettingsKeys.FILE_SEQ)
        settings.setInteger(fileId+1, forKey: SettingsKeys.FILE_SEQ)
        return fileId
    }
}