//
//  PackManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Marshal
 
struct Cycle: Unmarshaling {
    let name: String
    let code: String
    let position: Int
 
    init(object: MarshaledObject) throws {
        self.name = try object.value(for: "name")
        self.code = try object.value(for: "code")
        self.position = try object.value(for: "position")
    }
}

struct Pack: Unmarshaling {
    let name: String
    let code: String
    let cycleCode: String
    let position: Int
    let released: Bool
    let settingsKey: String
    
    init(object: MarshaledObject) throws {
        self.name = try object.value(for: "name")
        self.code = try object.value(for: "code")
        self.cycleCode = try object.value(for: "cycle_code")
        self.position = try object.value(for: "position")
        
        self.settingsKey = "use_" + self.code
        let date: String = try object.value(for: "date_release") ?? ""
        self.released = date.length > 0
    }
    
    init(named: String, key: String = "") {
        self.name = named
        self.code = ""
        self.cycleCode = ""
        self.position = 0
        self.released = false
        self.settingsKey = key
    }
}

class PackManager: NSObject {
    static let draftSetCode = "draft"
    static let coreSetCode = "core"
    static let unknownSet = "unknown"
    
    static let cyclesFilename = "nrcycles2.json"
    static let packsFilename = "nrpacks2.json"
    
    static var cyclesByCode = [String: Cycle]()     // code -> cycle
    static var allCycles = [Int: Cycle]()           // position -> cycles
    static var packsByCode = [String: Pack]()       // code -> pack
    static var allPacks = [Pack]()
    
    private static let rotatedCycles = [
        "genesis", "spin"       // 1st rotation, mid-2017
    ]
    private static let rotatedPacks = [
        "wla", "ta", "ce", "asis", "hs", "fp",  // genesis
        "om", "st", "mt", "tc", "fal", "dt"     // spin
    ]
    
    static let anyPack = Pack(named: Constant.kANY)
    
    // caches
    static var disabledPacks: Set<String>?          // set of pack codes
    static var enabledPacks: TableData?
        
    class var packsAvailable: Bool {
        return allPacks.count > 0
    }
    
    class func nameFor(key: String) -> String? {
        if let index = allPacks.index(where: {$0.settingsKey == key}) {
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
    
    class func packNumberFor(code: String) -> Int {
        if let pack = packsByCode[code], let cycle = cyclesByCode[pack.cycleCode] {
            return cycle.position * 1000 + pack.position
        }
        return 0
    }
    
    class func disabledPackCodes() -> Set<String> {
        if disabledPacks == nil {
            var disabled = Set<String>()
            let settings = UserDefaults.standard
            for pack in allPacks {
                if !settings.bool(forKey: pack.settingsKey) {
                    disabled.insert(pack.code)
                }
            }
    
            if !settings.bool(forKey: SettingsKeys.USE_DRAFT) {
                disabled.insert(draftSetCode)
            }
    
            disabledPacks = disabled
        }
    
        return disabledPacks!
    }
    
    class func rotatedPackCodes() -> Set<String> {
        var packs = Set<String>(PackManager.rotatedPacks)
        packs.insert(draftSetCode)
        return packs
    }
    
    class func draftPackCode() -> Set<String> {
        if UserDefaults.standard.bool(forKey: SettingsKeys.USE_DRAFT) {
            return Set<String>()
        } else {
            return Set<String>([draftSetCode])
        }
    }
    
    class func clearDisabledPacks() {
        disabledPacks = nil
        enabledPacks = nil
    }
    
    class func packsForTableview(packUsage: NRPackUsage) -> TableData {
        switch packUsage {
        case .all:
            return allKnownPacksForTableview()
        case .selected:
            return allEnabledPacksForTableview()
        case .allAfterRotation:
            return allPacksAfterRotationForTableview()
        }
    }
    
    class func allKnownPacksForSettings() -> TypedTableData<Pack> {
        var sections = [String]()
        var values = [[Pack]]()
        
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        return TypedTableData(sections: sections, values: values)
    }


    private class func allEnabledPacksForTableview() -> TableData {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        let settings = UserDefaults.standard
        
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code && settings.bool(forKey: $0.settingsKey) }
            
            if packs.count > 0 {
                values.append(packs)
            } else {
                sections.removeLast()
            }
        }
        
        assert(values.count == sections.count, "count mismatch")
        
        let result = TableData(sections: sections as NSArray, andValues: values as NSArray)
        let count = sections.count
        
        // collapse everything but the two last cycles
        var collapsedSections = [Bool](repeating: true, count: count)
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
        
        let useDraft = UserDefaults.standard.bool(forKey: SettingsKeys.USE_DRAFT)
        
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            
            if cycle.code == draftSetCode && !useDraft {
                continue
            }
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        return TableData(sections: sections as NSArray, andValues: values as NSArray)
    }
    
    private class func allPacksAfterRotationForTableview() -> TableData {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            if !rotatedCycles.contains(cycle.code) {
                sections.append(cycle.name)
                
                let packs = allPacks.filter{ $0.cycleCode == cycle.code }
                values.append(packs)
            }
        }
        
        return TableData(sections: sections as NSArray, andValues: values as NSArray)
    }

    class func packsUsedIn(deck: Deck) -> [String] {
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
            if let used = cardsUsed[pack.code], let needed = packsUsed[pack.code] {
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
    
    class func mostRecentPackUsedIn(deck: Deck) -> String {
        var maxIndex = 0
        
        for cc in deck.allCards {
            if let index = allPacks.index(where: { $0.code == cc.card.packCode}) {
                maxIndex = max(index, maxIndex)
            }
        }
        
        return allPacks[maxIndex].name
    }
    
    // MARK: - persistence
    
    class func packsPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.appendPathComponent(PackManager.packsFilename)
    }
    
    class func cyclesPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.appendPathComponent(PackManager.cyclesFilename)
    }
    
    class func removeFiles() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: packsPathname())
        _ = try? fileMgr.removeItem(atPath: cyclesPathname())
        
        CardManager.initialize()
    }
    
    class func setupFromFiles(_ language: String) -> Bool {
        let packsFile = packsPathname()
        let cyclesFile = cyclesPathname()
        
        let fileMgr = FileManager.default
                
        if let packsData = fileMgr.contents(atPath: packsFile), let cyclesData = fileMgr.contents(atPath: cyclesFile) {
            do {
                let packs = try JSONParser.JSONObjectWithData(packsData)
                let cycles = try JSONParser.JSONObjectWithData(cyclesData)
                return setupFromJsonData(cycles, packs, language: language)
            } catch {
                return false
            }
        }
        
        // print("app start: missing pack/cycles files")
        return false
    }
    
    class func setupFromNetrunnerDb(_ cyclesData: Data, _ packsData: Data, language: String) -> Bool {
        var ok = false
        do {
            let cyclesJson = try JSONParser.JSONObjectWithData(cyclesData)
            let packsJson = try JSONParser.JSONObjectWithData(packsData)
            ok = setupFromJsonData(cyclesJson, packsJson, language: language)
            if !ok {
                return false
            }
            
            let cyclesFile = self.cyclesPathname()
            try cyclesData.write(to: URL(fileURLWithPath: cyclesFile), options: .atomic)
            AppDelegate.excludeFromBackup(cyclesFile)
            
            let packsFile = self.packsPathname()
            try packsData.write(to: URL(fileURLWithPath: packsFile), options: .atomic)
            AppDelegate.excludeFromBackup(packsFile)
        } catch {
            ok = false
        }
        
        return ok
    }
    
    class func setupFromJsonData(_ cycles: JSONObject, _ packs: JSONObject, language: String) -> Bool {
        cyclesByCode = [String: Cycle]()     // code -> cycle
        allCycles = [Int: Cycle]()           // position -> cycles
        packsByCode = [String: Pack](minimumCapacity: 64)       // code -> pack
        allPacks = [Pack]()
        allPacks.reserveCapacity(100)
        
        let ok = NRDB.validJsonResponse(json: cycles) && NRDB.validJsonResponse(json: packs)
        if !ok {
            // print("cards/packs invalid")
            return false
        }
        
        do {
            let cycles: [Cycle] = try cycles.value(for: "data")
            for c in cycles {
                cyclesByCode[c.code] = c
                allCycles[c.position] = c
            }
            
            let packs: [Pack] = try packs.value(for: "data")
            for p in packs {
                packsByCode[p.code] = p
                allPacks.append(p)
            }
        } catch {
            return false
        }
        
        // sort packs in release order
        allPacks.sort { p1, p2 in
            let c1 = cyclesByCode[p1.cycleCode]?.position ?? -1
            let c2 = cyclesByCode[p2.cycleCode]?.position ?? -1
            if c1 == c2 {
                return p1.position < p2.position
            } else {
                return c1 < c2
            }
        }
        
        UserDefaults.standard.register(defaults: PackManager.settingsDefaults())
        return true
    }

}

