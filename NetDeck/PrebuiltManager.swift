//
//  PrebuiltManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.08.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Marshal
import SwiftyUserDefaults

struct Prebuilt: Unmarshaling {
    let name: String
    let settingsKey: String
    let released: Bool
    let cards: [CardCounter]
    
    init(object: MarshaledObject) throws {
        self.name = try object.value(for: "name")
        let code: String = try object.value(for: "code")
        self.settingsKey = Pack.use + code
        
        let date: String = try object.value(for: "date_release") ?? ""
        self.released = date != "" && PackManager.now() >= date
        
        let rotationActive = Defaults[.rotationActive]
        var cc = [CardCounter]()
        if let cards = object.optionalAny(for: "cards") as? [String: Int] {
            for (code, qty) in cards {
                if let card = CardManager.cardBy(code: code) {
                    let pack = PackManager.packsByCode[card.packCode]
                    let rotated = pack?.rotated ?? false
                    if rotationActive ? !rotated : true {
                        cc.append(CardCounter(card: card, count: qty))
                    }
                }
            }
        }
        self.cards = cc
    }
}

class PrebuiltManager {
    
    static var allPrebuilts = [Prebuilt]()
    
    // caches
    private static var prebuiltCards: [CardCounter]?
    private static var prebuiltCodes: [String]?
    
    // array of card codes in selected prebuilt decks
    static func availableCodes() -> [String]? {
        prepareCaches()
        guard let codes = prebuiltCodes, codes.count > 0 else {
            return nil
        }
        return codes
    }
    
    // array of identity card codes for role in selected prebuilt decks
    static func identities(for role: Role) -> [String]? {
        prepareCaches()
        guard let cards = prebuiltCards else { return nil }
        return cards.filter{ $0.card.role == role && $0.card.type == .identity }.map{ $0.card.code }
    }
    
    // quantity of card owned from prebuilt decks
    static func quantity(for card: Card) -> Int {
        prepareCaches()
        guard let cards = prebuiltCards else { return 0 }
        return cards.filter { $0.card.code == card.code }.reduce(0) { $0 + $1.count }
    }
    
    static func resetSelected() {
        prebuiltCards = nil
        prebuiltCodes = nil
    }
    
    private static func prepareCaches() {
        if prebuiltCards == nil {
            prebuiltCards = []
            prebuiltCodes = []
            
            let settings = UserDefaults.standard
            for prebuilt in allPrebuilts {
                if settings.bool(forKey: prebuilt.settingsKey) {
                    prebuiltCards?.append(contentsOf: prebuilt.cards)
                    prebuiltCodes?.append(contentsOf: prebuilt.cards.map { $0.card.code })
                }
            }
        }
    }
    
    // MARK: - persistence
    static func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.appendPathComponent("prebuilts.json")
    }
    
    static func removeFiles() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: filename())
    }
    
    static func setupFromFiles(_ language: String) -> Bool {
        if let data = FileManager.default.contents(atPath: self.filename()) {
            do {
                let prebuiltJson = try JSONParser.JSONObjectWithData(data)
                return setupFromJsonData(prebuiltJson, language: language)
            } catch let error {
                print("\(error)")
                return false
            }
        }
        
        // print("app start: missing pack/cycles files")
        return false
    }
    
    static func setupFromNetrunnerDb(_ data: Data, language: String) -> Bool {
        var ok = false
        do {
            let prebuiltJson = try JSONParser.JSONObjectWithData(data)
            ok = setupFromJsonData(prebuiltJson, language: language)
            if !ok {
                return false
            }
            
            let filename = self.filename()
            try data.write(to: URL(fileURLWithPath: filename), options: .atomic)
            AppDelegate.excludeFromBackup(filename)
        } catch let error {
            print("\(error)")
            ok = false
        }
        
        return ok
    }
    
    static func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        allPrebuilts.forEach { defaults[$0.settingsKey] = $0.released }
        return defaults
    }
    
    static func setupFromJsonData(_ prebuilts: JSONObject, language: String) -> Bool {
        let ok = NRDB.validJsonResponse(json: prebuilts)
        if !ok {
            // print("prebuilts invalid")
            return false
        }
        
        do {
            PrebuiltManager.allPrebuilts = try prebuilts.value(for: "data", discardingErrors: true)
        } catch let error {
            print("\(error)")
            return false
        }
        
        UserDefaults.standard.register(defaults: PrebuiltManager.settingsDefaults())
        return true
    }
    
}

