//
//  PrebuiltManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.08.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import SwiftyJSON

class Prebuilt {
    var name = ""
    var settingsKey = ""
    var cards = [CardCounter]()
}

class PrebuiltManager: NSObject {
    
    static var allPrebuilts = [Prebuilt]()
    
    // caches
    private static var prebuiltCards: [CardCounter]?
    private static var prebuiltCodes: [String]?
    
    // array of card codes in selected prebuilt decks
    class func availableCodes() -> [String]? {
        prepareCaches()
        guard let codes = prebuiltCodes where codes.count > 0 else { return nil }
        return codes
    }
    
    // array of identity card codes for role in selected prebuilt decks
    class func identities(role: NRRole) -> [String]? {
        prepareCaches()
        guard let cards = prebuiltCards else { return nil }
        return cards.filter{ $0.card.role == role && $0.card.type == .Identity }.map{ $0.card.code }
    }
    
    // quantity of card owned from prebuilt decks
    class func quantityFor(card: Card) -> Int {
        prepareCaches()
        guard let cards = prebuiltCards else { return 0 }
        return cards.filter { $0.card == card }.reduce(0) { $0 + $1.count }
    }
    
    class func resetSelected() {
        prebuiltCards = nil
        prebuiltCodes = nil
    }
    
    private class func prepareCaches() {
        if prebuiltCards == nil {
            prebuiltCards = [CardCounter]()
            prebuiltCodes = [String]()
            let settings = NSUserDefaults.standardUserDefaults()
            
            for prebuilt in allPrebuilts {
                if settings.boolForKey(prebuilt.settingsKey) {
                    prebuiltCards?.appendContentsOf(prebuilt.cards)
                    prebuiltCodes?.appendContentsOf(prebuilt.cards.map { $0.card.code })
                }
            }
        }
    }
    
    // MARK: - persistence
    class func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.stringByAppendingPathComponent("prebuilts.json")
    }
    
    class func removeFiles() {
        let fileMgr = NSFileManager.defaultManager()
        _ = try? fileMgr.removeItemAtPath(filename())
    }
    
    class func setupFromFiles(language: String) -> Bool {
        let filename = self.filename()
        
        let fileMgr = NSFileManager.defaultManager()
        
        if fileMgr.fileExistsAtPath(filename) {
            let str = try? NSString(contentsOfFile: filename, encoding: NSUTF8StringEncoding)
            
            if str != nil {
                let prebuiltJson = JSON.parse(str! as String)
                return setupFromJsonData(prebuiltJson, language: language)
            }
        }
        // print("app start: missing pack/cycles files")
        return false
    }
    
    class func setupFromNetrunnerDb(prebuilts: JSON, language: String) -> Bool {
        let ok = setupFromJsonData(prebuilts, language: language)
        if ok {
            let filename = self.filename()
            if let data = try? prebuilts.rawData() {
                data.writeToFile(filename, atomically:true)
                // print("write prebuilts ok=\(ok)")
            }
            AppDelegate.excludeFromBackup(filename)
        }
        return ok
    }
    
    class func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        for pack in allPrebuilts {
            defaults[pack.settingsKey] = false
        }
        return defaults
    }
    
    class func setupFromJsonData(prebuilts: JSON, language: String) -> Bool {
        let ok = prebuilts.validNrdbResponse
        if !ok {
            // print("prebuilts invalid")
            return false
        }
        
        for prebuilt in prebuilts["data"].arrayValue {
            let pb = Prebuilt()
            
            pb.name = prebuilt["name"].stringValue
            pb.settingsKey = "use_" + prebuilt["code"].stringValue
            for (code, qty) in prebuilt["cards"].dictionaryValue {
                if let card = CardManager.cardByCode(code) where qty.intValue > 0 {
                    let cc = CardCounter(card: card, count: qty.intValue)
                    pb.cards.append(cc)
                }
            }
            
            PrebuiltManager.allPrebuilts.append(pb)
        }
        
        NSUserDefaults.standardUserDefaults().registerDefaults(PrebuiltManager.settingsDefaults())
        return true
    }
    
}

