//
//  PackManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.11.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Marshal
import SwiftyUserDefaults

struct Cycle: Unmarshaling {
    let name: String
    let code: String
    let position: Int
    let rotated: Bool
 
    init(object: MarshaledObject) throws {
        self.name = try object.value(for: "name")
        self.code = try object.value(for: "code")
        self.position = try object.value(for: "position")
        self.rotated = try object.value(for: "rotated") ?? false
    }
}

struct Pack: Unmarshaling {
    let name: String
    let code: String
    let cycleCode: String
    let position: Int
    let released: Bool
    let settingsKey: String
    let rotated: Bool
    
    static let use = "use_"
    
    private static let testRotation = false
    
    init(object: MarshaledObject) throws {
        self.name = try object.value(for: "name")
        self.code = try object.value(for: "code")
        self.cycleCode = try object.value(for: "cycle_code")
        self.position = try object.value(for: "position")
        self.settingsKey = Pack.use + self.code
        
        if BuildConfig.debug && Pack.testRotation {
            self.rotated = ["genesis", "spin"].contains(self.cycleCode)
        } else {
            self.rotated = PackManager.cyclesByCode[self.cycleCode]?.rotated ?? false
        }
        
        let date: String = try object.value(for: "date_release") ?? ""
        self.released = date != "" && PackManager.now() >= date
    }
    
    init(named: String, key: String = "") {
        self.name = named
        self.code = ""
        self.cycleCode = ""
        self.position = 0
        self.released = false
        self.settingsKey = key
        self.rotated = false
    }
}

class PackManager {
    static let unknown = "unknown"
    static let draft = "draft"
    
    static let core = "core"
    
    static let creationAndControl = "cac"
    static let honorAndProfit = "hap"
    static let orderAndChaos = "oac"
    static let dataAndDestiny = "dad"
    static let terminalDirective = "td"
    
    static let deluxes = [ creationAndControl, honorAndProfit, orderAndChaos, dataAndDestiny ]
    static let campaigns = [ terminalDirective ]
    
    static let cyclesFilename = "nrcycles2.json"
    static let packsFilename = "nrpacks2.json"
    
    fileprivate static var cyclesByCode = [String: Cycle]()     // code -> cycle
    private static var allCycles = [Int: Cycle]()               // position -> cycles
    private(set) static var packsByCode = [String: Pack]()      // code -> pack
    private(set) static var allPacks = [Pack]()
    
    static let anyPack = Pack(named: Constant.kANY)
    
    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    static func now() -> String {
        return fmt.string(from: Date())
    }

    static var packsAvailable: Bool {
        return allPacks.count > 0
    }
    
    static func nameFor(key: String) -> String? {
        if let index = allPacks.index(where: {$0.settingsKey == key}) {
            return allPacks[index].name
        }
        return nil
    }

    static func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        allPacks.forEach { defaults[$0.settingsKey] = $0.released }
        return defaults
    }
    
    static func packNumberFor(code: String) -> Int {
        if let pack = packsByCode[code], let cycle = cyclesByCode[pack.cycleCode] {
            return cycle.position * 1000 + pack.position
        }
        return 0
    }
    
    static func disabledPackCodes() -> Set<String> {
        let settings = UserDefaults.standard
        var disabled = Set<String>()
        for pack in allPacks {
            if !settings.bool(forKey: pack.settingsKey) {
                disabled.insert(pack.code)
            }
        }

        if !Defaults[.useDraft] {
            disabled.insert(draft)
        }

        return disabled
    }
    
    static func packsForTableView(packUsage: PackUsage) -> TableData<String> {
        let rawPacks: TableData<Pack> = self.packsForTableView(packUsage: packUsage)
        var strValues = [[String]]()
        for packs in rawPacks.values {
            var strings = [String]()
            for pack in packs {
                strings.append(pack.name)
            }
            strValues.append(strings)
        }
        
        let stringPacks = TableData<String>(sections: rawPacks.sections, values: strValues)
        stringPacks.collapsedSections = rawPacks.collapsedSections
        
        return stringPacks
    }
    
    static func packsForTableView(packUsage: PackUsage) -> TableData<Pack> {
        switch packUsage {
        case .all:
            return allKnownPacksForTableView()
        case .selected:
            return allEnabledPacksForTableView()
        }
    }
    
    static func allKnownPacksForSettings() -> TableData<Pack> {
        var sections = [String]()
        var values = [[Pack]]()
        
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        return TableData(sections: sections, values: values)
    }


    private static func allEnabledPacksForTableView() -> TableData<Pack> {
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
        
        let result = TableData(sections: sections, values: values)
        return collapseOldCycles(result)
    }

    private static func allKnownPacksForTableView() -> TableData<Pack> {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        let useDraft = Defaults[.useDraft]
        
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            
            if cycle.code == draft && !useDraft {
                continue
            }
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        let result = TableData(sections: sections, values: values)
        return collapseOldCycles(result)
    }
    
    private static func collapseOldCycles(_ data: TableData<Pack>) -> TableData<Pack> {
        let count = data.sections.count
        
        // collapse everything but the two last cycles
        var collapsedSections = [Bool](repeating: true, count: count)
        collapsedSections[0] = false
        if count-1 > 0 {
            collapsedSections[count-1] = false
        }
        if count-2 > 0 {
            collapsedSections[count-2] = false
        }
        
        data.collapsedSections = collapsedSections
        return data
    }

    static func packsUsedIn(deck: Deck) -> [String] {
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
    
    static func mostRecentPackUsedIn(deck: Deck) -> String {
        var maxIndex = -1
        
        for cc in deck.allCards {
            if let index = allPacks.index(where: { $0.code == cc.card.packCode}) {
                maxIndex = max(index, maxIndex)
            }
        }
        
        return maxIndex == -1 ? "n/a" : allPacks[maxIndex].name
    }
    
    static func cycleForPack(_ packCode: String) -> String? {
        if let pack = packsByCode[packCode] {
            return pack.cycleCode
        }
        return nil
    }
    
    static func keysForCycle(_ cycleCode: String) -> [String] {
        return self.allPacks.filter { $0.cycleCode == cycleCode }.map { $0.settingsKey }
    }
    
    // MARK: - persistence
    
    static func filesExist() -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: packsPathname()) && fm.fileExists(atPath: cyclesPathname())
    }
    
    static func packsPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.appendPathComponent(PackManager.packsFilename)
    }
    
    static func cyclesPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.appendPathComponent(PackManager.cyclesFilename)
    }
    
    static func removeFiles() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: packsPathname())
        _ = try? fileMgr.removeItem(atPath: cyclesPathname())
        
        CardManager.initialize()
    }
    
    static func setupFromFiles(_ language: String) -> Bool {
        let packsFile = packsPathname()
        let cyclesFile = cyclesPathname()
        
        let fileMgr = FileManager.default
                
        if let packsData = fileMgr.contents(atPath: packsFile), let cyclesData = fileMgr.contents(atPath: cyclesFile) {
            do {
                let cycles = try JSONParser.JSONObjectWithData(cyclesData)
                let packs = try JSONParser.JSONObjectWithData(packsData)
                return setupFromJsonData(cycles, packs, language: language)
            } catch let error {
                print("\(error)")
                return false
            }
        }
        
        // print("app start: missing pack/cycles files")
        return false
    }
    
    static func setupFromNetrunnerDb(_ cyclesData: Data, _ packsData: Data, language: String) -> Bool {
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
        } catch let error {
            print("\(error)")
            ok = false
        }
        
        return ok
    }
    
    static func setupFromJsonData(_ cycles: JSONObject, _ packs: JSONObject, language: String) -> Bool {
        cyclesByCode = [:]  // code -> cycle
        allCycles = [:]     // position -> cycles
        packsByCode = [:]   // code -> pack
        allPacks = []
        
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
        } catch let error {
            print("\(error)")
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

