//
//  PrebuiltManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.08.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Marshal

struct Prebuilt: Unmarshaling {
    private(set) var name = ""
    private(set) var settingsKey = ""
    private(set) var cards = [CardCounter]()
    
    init(object: MarshaledObject) throws {
        self.name = try object.value(for: "name")
        let code: String = try object.value(for: "code")
        self.settingsKey = "use_" + code
    
        if let cards = try object.any(for: "cards") as? [String: Int] {
            for (code, qty) in cards {
                if let card = CardManager.cardBy(code: code) {
                    self.cards.append(CardCounter(card: card, count: qty))
                }
            }
        }
    }
}

class PrebuiltManager: NSObject {
    
    static var allPrebuilts = [Prebuilt]()
    
    // caches
    private static var prebuiltCards: [CardCounter]?
    private static var prebuiltCodes: [String]?
    
    // array of card codes in selected prebuilt decks
    class func availableCodes() -> [String]? {
        prepareCaches()
        guard let codes = prebuiltCodes , codes.count > 0 else { return nil }
        return codes
    }
    
    // array of identity card codes for role in selected prebuilt decks
    class func identities(for role: NRRole) -> [String]? {
        prepareCaches()
        guard let cards = prebuiltCards else { return nil }
        return cards.filter{ $0.card.role == role && $0.card.type == .identity }.map{ $0.card.code }
    }
    
    // quantity of card owned from prebuilt decks
    class func quantity(for card: Card) -> Int {
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
    class func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.appendPathComponent("prebuilts.json")
    }
    
    class func removeFiles() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: filename())
    }
    
    class func setupFromFiles(_ language: String) -> Bool {
        if let data = FileManager.default.contents(atPath: self.filename()) {
            do {
                let prebuiltJson = try JSONParser.JSONObjectWithData(data)
                return setupFromJsonData(prebuiltJson, language: language)
            } catch {
                return false
            }
        }
        
        // print("app start: missing pack/cycles files")
        return false
    }
    
    class func setupFromNetrunnerDb(_ prebuilts: Any, language: String) -> Bool {
//        var ok = setupFromJsonData(prebuilts, language: language)
//        if ok {
//            let filename = self.filename()
//            if let data = try? prebuilts.rawData() {
//                do {
//                    try data.write(to: URL(fileURLWithPath: filename), options: .atomic)
//                } catch {
//                    ok = false
//                }
//                // print("write prebuilts ok=\(ok)")
//            }
//            AppDelegate.excludeFromBackup(filename)
//        }
//        return ok
        return false
    }
    
    class func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        for pack in allPrebuilts {
            defaults[pack.settingsKey] = false
        }
        return defaults
    }
    
    class func setupFromJsonData(_ prebuilts: JSONObject, language: String) -> Bool {
        let ok = prebuilts.validNrdbResponse
        if !ok {
            // print("prebuilts invalid")
            return false
        }
        
        do {
            PrebuiltManager.allPrebuilts = try prebuilts.value(for: "data")
        }
        catch {
            return false
        }
        
        UserDefaults.standard.register(defaults: PrebuiltManager.settingsDefaults())
        return true
    }
    
}

