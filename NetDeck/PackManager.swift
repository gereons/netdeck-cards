//
//  PackManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.11.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import SwiftyUserDefaults

struct Cycle: Codable {
    let name: String
    let code: String
    fileprivate(set) var position: Int
    let size: Int
    let rotated: Bool
 
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Cycle.CodingKeys.self)

        self.name = try container.decode(String.self, forKey: .name)
        self.code = try container.decode(String.self, forKey: .code)
        self.position = try container.decode(Int.self, forKey: .position)
        self.size = try container.decode(Int.self, forKey: .size)

        self.rotated = RotationManager.rotatedPacks.cycles.contains(self.code)
    }
}

struct Pack: Codable {
    let name: String
    let code: String
    let cycleCode: String
    let position: Int
    let releaseDate: String?
    let ffgId: Int?

    let settingsKey: String
    let rotated: Bool
    var released: Bool {
        guard
            let releaseDate = self.releaseDate,
            let date = Pack.dateFormatter.date(from: releaseDate)
        else {
            return false
        }

        let now = Date()
        return now >= date
    }

    enum CodingKeys: String, CodingKey {
        case name
        case code
        case cycleCode = "cycle_code"
        case position
        case releaseDate = "date_release"
        case ffgId = "ffg_id"
    }
    
    static let use = "use_"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Pack.CodingKeys.self)

        self.name = try container.decode(String.self, forKey: .name)
        self.cycleCode = try container.decode(String.self, forKey: .cycleCode)
        self.position = try container.decode(Int.self, forKey: .position)
        self.code = try container.decode(String.self, forKey: .code)
        self.releaseDate = try? container.decode(String.self, forKey: .releaseDate)
        self.ffgId = try? container.decode(Int.self, forKey: .ffgId)

        self.settingsKey = Pack.use + code
        self.rotated = RotationManager.rotatedPacks.packs.contains(code)
    }
    
    init(named: String, key: String) {
        self.name = named
        self.code = ""
        self.cycleCode = ""
        self.position = 0
        self.settingsKey = key
        self.rotated = false
        self.releaseDate = nil
        self.ffgId = nil
    }
}

final class PackManager {
    static let unknown = "unknown"
    static let draft = "draft"
    static let napd = "napd"

    static let core = "core"
    static let core2 = "core2"
    static let sc19 = "sc19"
    static let su21 = "su21"

    static let systemGateway = "sg"
    static let uprising = "ur"
    static let downfall = "df"

    static let creationAndControl = "cac"
    static let honorAndProfit = "hap"
    static let orderAndChaos = "oac"
    static let dataAndDestiny = "dad"
    static let terminalDirective = "td"
    static let reignAndReverie = "rar"
    static let magnumOpus = "mo"
    static let magnumOpusReprint = "mor"
    static let uprisingBooster = "urbp"

    static let deluxeBoxes = [ creationAndControl, honorAndProfit, orderAndChaos, dataAndDestiny, reignAndReverie ]
    static let campaignBoxes = [ terminalDirective ]
    static let bigBoxes = deluxeBoxes + campaignBoxes
    static let terminalDirectiveCampaign = "tdc"

    static let cores = [ core, core2, sc19, su21 ]

    static let cyclesFilename = "nrcycles2.json"
    static let packsFilename = "nrpacks2.json"

    static let startup21 = [ su21, systemGateway, uprising, downfall ]
    
    static private(set) var cacheRefreshCycles = [String]()
    
    fileprivate static var cyclesByCode = [String: Cycle]()     // code -> cycle
    private(set) static var allCycles = [Int: Cycle]()          // position -> cycles
    private(set) static var packsByCode = [String: Pack]()      // code -> pack
    private(set) static var allPacks = [Pack]()
    
    static let anyPack = Pack(named: Constant.kANY, key: "")

    static func isPackDisabled(_ code: String) -> Bool {
        return self.disabledPackCodes().contains(code)
    }
    
    static var packsAvailable: Bool {
        return allPacks.count > 0
    }
    
    static func nameFor(key: String) -> String? {
        if let index = allPacks.firstIndex(where: {$0.settingsKey == key}) {
            return allPacks[index].name
        }
        return nil
    }

    static func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        allPacks.forEach {
            defaults[$0.settingsKey] = $0.released
        }
        
        if Defaults[.rotationActive] {
            RotationManager.rotatedPacks.packs.forEach { pack in
                defaults[Pack.use + pack] = false
            }
        } else {
            defaults[DefaultsKeys.useCore2._key] = false
            defaults[DefaultsKeys.useSC19._key] = false
        }

        defaults[Pack.use + PackManager.uprisingBooster] = false
        defaults[Pack.use + PackManager.magnumOpus] = false
        defaults[Pack.use + PackManager.terminalDirectiveCampaign] = false
        return defaults
    }
    
    static func packNumberFor(code: String) -> Int {
        if let pack = packsByCode[code], let cycle = cyclesByCode[pack.cycleCode] {
            return cycle.position * 1000 + pack.position
        }
        return 0
    }
    
    static func packsInCycle(code: String) -> [Pack] {
        return allPacks.filter { $0.cycleCode == code }
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
    
    static func rotatedPackCodes() -> Set<String> {
        if Defaults[.rotationActive] {
            let rotation = RotationManager.rotatedPacks
            return rotation.packs
        } else {
            return Set([])
        }
    }
    
    static func rotatedPackKeys() -> [String] {
        return rotatedPackCodes().map { Pack.use + $0 }
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
        
        let stringPacks = TableData(sections: rawPacks.sections, values: strValues)
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

        var coreNames = [String]()
        var corePacks = [[Pack]]()
        // sort cycles by position
        for cycle in allCycles.values.sorted(by: { $0.position < $1.position }) {
            let packs = allPacks.filter { $0.cycleCode == cycle.code }

            if [PackManager.core2, PackManager.sc19].contains(cycle.code) {
                coreNames.append(cycle.name)
                corePacks.append(packs)
            } else {
                sections.append(cycle.name)
                values.append(packs)
            }
        }

        for index in 0..<coreNames.count {
            values[1].append(contentsOf: corePacks[index])
        }

        return TableData(sections: sections.reversed(), values: values.reversed())
    }

    private static func allEnabledPacksForTableView() -> TableData<Pack> {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        let settings = UserDefaults.standard
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            sections.append(cycle.name)
            
            let packs = allPacks.filter { $0.cycleCode == cycle.code && settings.bool(forKey: $0.settingsKey) }
            
            if packs.count > 0 {
                values.append(packs)
            } else {
                sections.removeLast()
            }
        }
        
        assert(values.count == sections.count, "count mismatch")
        
        let result = TableData(sections: sections.reversed(), values: values.reversed())
        return collapseOldCycles(result)
    }

    private static func allKnownPacksForTableView() -> TableData<Pack> {
        var sections = [String]()
        var values = [[Pack]]()
        
        sections.append("")
        values.append([PackManager.anyPack])
        
        let useDraft = Defaults[.useDraft]
        let rotationActive = Defaults[.rotationActive]
        
        for (_, cycle) in allCycles.sorted(by: { $0.0 < $1.0 }) {
            if cycle.code == draft && !useDraft {
                continue
            }
            if rotationActive && (cycle.rotated || cycle.code == PackManager.core) {
                continue
            }
            if !rotationActive && cycle.code == PackManager.core2 {
                continue
            }
            sections.append(cycle.name)
            
            let packs = allPacks.filter { $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        let result = TableData(sections: sections.reversed(), values: values.reversed())
        return collapseOldCycles(result)
    }
    
    private static func collapseOldCycles(_ data: TableData<Pack>) -> TableData<Pack> {
        let count = data.sections.count
        
        // collapse everything but the two last cycles
        var collapsedSections = [Bool](repeating: true, count: count)
        if count > 0 {
            collapsedSections[0] = false
            collapsedSections[count - 1] = false
        }
        if count > 1 {
            collapsedSections[1] = false
        }
        
        data.collapsedSections = collapsedSections
        return data
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
        
        // CardManager.initialize()
    }
    
    static func setupFromFiles() -> Bool {
        let packsFile = packsPathname()
        let cyclesFile = cyclesPathname()
        
        let fileMgr = FileManager.default

        if !fileMgr.fileExists(atPath: packsFile) {
            // copy the files from our bundle
            if let bundlePath = Bundle.main.path(forResource: "packs_en", ofType: "json") {
                do {
                    try fileMgr.copyItem(atPath: bundlePath, toPath: packsFile)
                } catch {
                    print(error)
                }
            }
            if let bundlePath = Bundle.main.path(forResource: "cycles_en", ofType: "json") {
                do {
                    try fileMgr.copyItem(atPath: bundlePath, toPath: cyclesFile)
                } catch {
                    print(error)
                }
            }
        }
                
        if let cyclesData = fileMgr.contents(atPath: cyclesFile), let packsData = fileMgr.contents(atPath: packsFile) {
            return setupFromJsonData(cyclesData, packsData)
        }
        
        // print("app start: missing pack/cycles files")
        return false
    }
    
    static func setupFromNetrunnerDb(_ cyclesData: Data, _ packsData: Data) -> Bool {
        let ok = setupFromJsonData(cyclesData, packsData)
        if !ok {
            return false
        }

        do {
            let cyclesFile = self.cyclesPathname()
            try cyclesData.write(to: URL(fileURLWithPath: cyclesFile), options: .atomic)
            Utils.excludeFromBackup(cyclesFile)

            let packsFile = self.packsPathname()
            try packsData.write(to: URL(fileURLWithPath: packsFile), options: .atomic)
            Utils.excludeFromBackup(packsFile)
        }
        catch let error {
            print("\(error)")
        }

        return ok
    }
    
    private static func reorderCycles(_ cycles: inout [Cycle]) {
        cycles.sort { $0.position < $1.position }
        
        guard
            let coreIndex = cycles.firstIndex(where: { $0.code == PackManager.core }),
            let core2Index = cycles.firstIndex(where: { $0.code == PackManager.core2 })
        else {
            return
        }
        
        let c2 = cycles.remove(at: core2Index)
        cycles.insert(c2, at: coreIndex + 1)

        if let sc19index = cycles.firstIndex(where: { $0.code == PackManager.sc19}) {
            let sc19 = cycles.remove(at: sc19index)
            cycles.insert(sc19, at: coreIndex + 2)
        }
        
        for i in 0 ..< cycles.count {
            cycles[i].position = i
        }
    }
    
    static func setupFromJsonData(_ cyclesData: Data, _ packsData: Data) -> Bool {
        cyclesByCode = [:]  // code -> cycle
        allCycles = [:]     // position -> cycles
        packsByCode = [:]   // code -> pack
        allPacks = []
        
        allPacks.reserveCapacity(100)
        
        do {
            let decoder = JSONDecoder()
            let rawCycles = try decoder.decode(ApiResponse<Cycle>.self, from: cyclesData)
            if !rawCycles.valid {
                return false
            }
            var cycles = rawCycles.data
            self.reorderCycles(&cycles)
            for c in cycles {
                cyclesByCode[c.code] = c
                allCycles[c.position] = c
            }
            
            let packs = try decoder.decode(ApiResponse<Pack>.self, from: packsData)
            if !packs.valid {
                return false
            }
            for p in packs.data {
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
        
        // get all "real" cycles and find the last two that have released packs
        let last2cycles = allCycles.values
            .filter { $0.size > 1 && !$0.rotated }
            .filter { packsInCycle(code: $0.code).filter { $0.released } .count > 0 }
            .sorted { $0.position > $1.position }
            .prefix(2)
        
        PackManager.cacheRefreshCycles = last2cycles.map { $0.code }
        
        UserDefaults.standard.register(defaults: PackManager.settingsDefaults())
        
        return true
    }

}

