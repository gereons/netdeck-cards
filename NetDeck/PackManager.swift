//
//  PackManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import SwiftyJSON

class Cycle {
    var name = ""
    var code = ""
    var position = 0
}

// TODO: make this swift-only
class Pack: NSObject {
    var name = ""
    var code = ""
    var cycleCode = ""
    var position = 0
    var released = false
    var settingsKey = ""
}

class PackManager: NSObject {
    static let DRAFT_SET_CODE = "draft"
    static let CORE_SET_CODE = "core"
    static let UNKNOWN_SET = "unknown"
    
    static let cyclesFilename = "nrcycles2.json"
    static let packsFilename = "nrpacks2.json"
    
    static var cyclesByCode = [String: Cycle]()     // code -> cycle
    static var allCycles = [Int: Cycle]()           // position -> cycles
    static var packsByCode = [String: Pack]()       // code -> pack
    static var allPacks = [Pack]()
    
    static let rotatedCycles = [
        "genesis", "spin"
    ]
    static let rotatedPacks = [
        "wla", "ta", "ce", "asis", "hs", "fp",  // genesis
        "om", "st", "mt", "tc", "fal", "dt"     // spin
    ]
    
    static let anyPack: Pack = {
        let p = Pack()
        p.name = Constant.kANY
        return p
    }()
    
    // caches
    static var disabledPacks: Set<String>?          // set of pack codes
    static var enabledPacks: TableData?
        
    
    class func packsAvailable() -> Bool {
        return allPacks.count > 0
    }
    
    class func nameForKey(key: String) -> String? {
        if let index = allPacks.indexOf({$0.settingsKey == key}) {
            return allPacks[index].name
        }
        return nil
    }

    class func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        for pack in allPacks {
            defaults[pack.settingsKey] = pack.released
        }
        return defaults
    }
    
    class func packNumberForCode(code: String) -> Int {
        if let pack = packsByCode[code], cycle = cyclesByCode[pack.cycleCode] {
            return cycle.position * 1000 + pack.position
        }
        return 0
    }
    
    class func disabledPackCodes() -> Set<String> {
        if disabledPacks == nil {
            var disabled = Set<String>()
            let settings = NSUserDefaults.standardUserDefaults()
            for pack in allPacks {
                if !settings.boolForKey(pack.settingsKey) {
                    disabled.insert(pack.code)
                }
            }
    
            if !settings.boolForKey(SettingsKeys.USE_DRAFT) {
                disabled.insert(DRAFT_SET_CODE)
            }
    
            disabledPacks = disabled
        }
    
        return disabledPacks!
    }
    
    class func rotatedPackCodes() -> Set<String> {
        return Set<String>(PackManager.rotatedPacks)
    }
    
    class func clearDisabledPacks() {
        disabledPacks = nil
        enabledPacks = nil
    }
    
    class func packsForTableview(packs: NRPackUsage) -> TableData {
        switch packs {
        case .All:
            return allKnownPacksForTableview()
        case .Selected:
            return allEnabledPacksForTableview()
        case .AllAfterRotation:
            return allPacksAfterRotationForTableview()
        }
    }
    
    class func allKnownPacksForSettings() -> TableData {
        var sections = [String]()
        var values = [[Pack]]()
        
        for (_, cycle) in allCycles.sort({ $0.0 < $1.0 }) {
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        return TableData(sections: sections, andValues: values)
    }


    private class func allEnabledPacksForTableview() -> TableData {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        let settings = NSUserDefaults.standardUserDefaults()
        
        for (_, cycle) in allCycles.sort({ $0.0 < $1.0 }) {
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code && settings.boolForKey($0.settingsKey) }
            
            if packs.count > 0 {
                values.append(packs)
            } else {
                sections.removeLast()
            }
        }
        
        assert(values.count == sections.count, "count mismatch")
        
        let result = TableData(sections: sections, andValues: values)
        let count = sections.count
        
        // collapse everything but the two last cycles
        var collapsedSections = [Bool](count: count, repeatedValue: true)
        collapsedSections[0] = false
        if count-1 > 0 {
            collapsedSections[count-1] = false
        }
        if count-2 > 0 {
            collapsedSections[count-2] = false
        }
        
        result.collapsedSections = collapsedSections
        return result
    }

    private class func allKnownPacksForTableview() -> TableData {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        let useDraft = NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.USE_DRAFT)
        
        for (_, cycle) in allCycles.sort({ $0.0 < $1.0 }) {
            
            if cycle.code == DRAFT_SET_CODE && !useDraft {
                continue
            }
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        return TableData(sections: sections, andValues: values)
    }
    
    private class func allPacksAfterRotationForTableview() -> TableData {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        for (_, cycle) in allCycles.sort({ $0.0 < $1.0 }) {
            if !rotatedCycles.contains(cycle.code) {
                sections.append(cycle.name)
                
                let packs = allPacks.filter{ $0.cycleCode == cycle.code }
                values.append(packs)
            }
        }
        
        return TableData(sections: sections, andValues: values)
    }

    class func packsUsedInDeck(deck: Deck) -> [String] {
        var packsUsed = [String: Int]() // pack code -> number of times used
        var cardsUsed = [String: Int]() // pack code -> number of cards used
            
        for cc in deck.allCards {
            let code = cc.card.packCode
            
            var used = packsUsed[code] ?? 1
            if cc.count > Int(cc.card.quantity) {
                let needed = Int(0.5 + Float(cc.count) / Float(cc.card.quantity))
                if needed > used {
                    used = needed
                }
            }
            packsUsed[code] = used
            
            var cardUsed = cardsUsed[code] ?? 0
            cardUsed += cc.count
            cardsUsed[code] = cardUsed
        }
        
        var result = [String]()
        for pack in allPacks {
            if let used = cardsUsed[pack.code], needed = packsUsed[pack.code] {
                let cards = used == 1 ? "Card".localized() : "Cards".localized()
                if needed > 1 {
                    result.append(String(format:"%d×%@ - %d %@", needed, pack.name, used, cards))
                }
                else {
                    result.append(String(format:"%@ - %d %@", pack.name, used, cards))
                }
            }
        }
        return result
    }
    
    class func mostRecentPackUsedInDeck(deck: Deck) -> String {
        var maxIndex = 0
        
        for cc in deck.allCards {
            if let index = allPacks.indexOf({ $0.code == cc.card.packCode}) {
                maxIndex = max(index, maxIndex)
            }
        }
        
        return allPacks[maxIndex].name
    }
    
    // MARK: - persistence
    
    class func packsPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.stringByAppendingPathComponent(PackManager.packsFilename)
    }
    
    class func cyclesPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.stringByAppendingPathComponent(PackManager.cyclesFilename)
    }
    
    class func removeFiles() {
        let fileMgr = NSFileManager.defaultManager()
        _ = try? fileMgr.removeItemAtPath(packsPathname())
        _ = try? fileMgr.removeItemAtPath(cyclesPathname())
        
        CardManager.initialize()
    }
    
    class func setupFromFiles(language: String) -> Bool {
        let packsFile = packsPathname()
        let cyclesFile = cyclesPathname()
        
        let fileMgr = NSFileManager.defaultManager()
        
        if fileMgr.fileExistsAtPath(packsFile) && fileMgr.fileExistsAtPath(cyclesFile) {
            let packsStr = try? NSString(contentsOfFile: packsFile, encoding: NSUTF8StringEncoding)
            let cyclesStr = try? NSString(contentsOfFile: cyclesFile, encoding: NSUTF8StringEncoding)
            
            if packsStr != nil && cyclesStr != nil {
                let packsJson = JSON.parse(packsStr! as String)
                let cyclesJson = JSON.parse(cyclesStr! as String)
                return setupFromJsonData(cyclesJson, packsJson, language: language)
            }
        }
        // print("app start: missing pack/cycles files")
        return false
    }
    
    class func setupFromNetrunnerDb(cycles: JSON, _ packs: JSON, language: String) -> Bool {
        let ok = setupFromJsonData(cycles, packs, language: language)
        if ok {
            let packsFile = packsPathname()
            if let data = try? packs.rawData() {
                data.writeToFile(packsFile, atomically:true)
                // print("write packs ok=\(ok)")
            }
            AppDelegate.excludeFromBackup(packsFile)
            
            let cyclesFile = cyclesPathname()
            if let data = try? cycles.rawData() {
                data.writeToFile(cyclesFile, atomically:true)
                // print("write cycles ok=\(ok)")
            }
            AppDelegate.excludeFromBackup(cyclesFile)
        }
        return ok
    }
    
    class func setupFromJsonData(cycles: JSON, _ packs: JSON, language: String) -> Bool {
        cyclesByCode = [String: Cycle]()     // code -> cycle
        allCycles = [Int: Cycle]()           // position -> cycles
        packsByCode = [String: Pack]()       // code -> pack
        allPacks = [Pack]()
        
        let ok = cycles.validNrdbResponse && packs.validNrdbResponse
        if !ok {
            // print("cards/packs invalid")
            return false
        }
        
        for cycle in cycles["data"].arrayValue {
            let c = Cycle()
            c.name = cycle.localized("name", language)
            c.position = cycle["position"].intValue
            c.code = cycle["code"].stringValue
            
            cyclesByCode[c.code] = c
            allCycles[c.position] = c
        }
        
        for pack in packs["data"].arrayValue {
            let p = Pack()
            p.name = pack.localized("name", language)
            p.code = pack["code"].stringValue
            p.position = pack["position"].intValue
            p.cycleCode = pack["cycle_code"].stringValue
            p.settingsKey = "use_" + p.code
            p.released = pack["date_release"].string != nil
            
            packsByCode[p.code] = p
            allPacks.append(p)
        }
        
        // sort packs in release order
        allPacks.sortInPlace { p1, p2 in
            let c1 = cyclesByCode[p1.cycleCode]?.position ?? -1
            let c2 = cyclesByCode[p2.cycleCode]?.position ?? -1
            if c1 == c2 {
                return p1.position < p2.position
            } else {
                return c1 < c2
            }
        }
        
        NSUserDefaults.standardUserDefaults().registerDefaults(PackManager.settingsDefaults())
        return true
    }

}

