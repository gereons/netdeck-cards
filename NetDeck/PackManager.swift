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

@objc class Pack: NSObject {
    var name = ""
    var code = ""
    var cycleCode = ""
    var position = 0
    var released = false
    var settingsKey = ""
}

@objc class PackManager: NSObject {
    static let DRAFT_SET_CODE = "draft"
    static let CORE_SET_CODE = "core"
    static let UNKNOWN_SET = "unknown"
    
    static let cyclesFilename = "nrcycles2.json"
    static let packsFilename = "nrpacks2.json"
    
    static var cyclesByCode = [String: Cycle]()     // code -> cycle
    static var allCycles = [Int: Cycle]()           // position -> cycles
    static var packsByCode = [String: Pack]()       // code -> pack
    static var allPacks = [Pack]()

    static var code2number = [String: Int]()        // map code -> number
    static var code2name = [String: String]()       // map code -> name
    static var setGroups = [String]()               // section names: 0=empty/any 1=core+deluxe, plus one for each cycle
    static var setsPerGroup = [NRCycle: [Int]]()    // one array per cycle, contains set numbers in that group
    static var keysPerCycle = [NRCycle: [String]]()    // "use_xyz" settings keys, per cycle
    
    // caches
    static var disabledPacks: Set<String>?          // set of pack codes
    static var enabledPacks: TableData!
    
    // map of NRDB's "cyclenumber" values to our NRCycle values
    static let cycleMap: [Int: NRCycle] = [
        1: .CoreDeluxe,
        2: .Genesis,
        3: .CoreDeluxe,
        4: .Spin,
        5: .CoreDeluxe,
        6: .Lunar,
        7: .CoreDeluxe,
        8: .SanSan,
        9: .CoreDeluxe,
        10: .Mumbad,
        11: .Flashpoint
    ]
    
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
        
        if fileMgr.fileExistsAtPath(packsFile) && fileMgr.fileExistsAtPath(cyclesFile){
            let packsStr = try? NSString(contentsOfFile: packsFile, encoding: NSUTF8StringEncoding)
            let cyclesStr = try? NSString(contentsOfFile: cyclesFile, encoding: NSUTF8StringEncoding)
            
            if packsStr != nil && cyclesStr != nil {
                let packsJson = JSON.parse(packsStr! as String)
                let cyclesJson = JSON.parse(cyclesStr! as String)
                return setupFromJsonData(cyclesJson, packsJson, language: language)
            }
        }
        print("app start: missing pack/cycles files")
        return false
    }
    
    class func setupFromNetrunnerDb(cycles: JSON, _ packs: JSON, language: String) -> Bool {
        let packsFile = packsPathname()
        if let data = try? packs.rawData() {
            let ok = data.writeToFile(packsFile, atomically:true)
            print("write packs ok=\(ok)")
        }
        AppDelegate.excludeFromBackup(packsFile)
        
        let cyclesFile = cyclesPathname()
        if let data = try? cycles.rawData() {
            let ok = data.writeToFile(cyclesFile, atomically:true)
            print("write cycles ok=\(ok)")
        }
        AppDelegate.excludeFromBackup(cyclesFile)
        
        return setupFromJsonData(cycles, packs, language: language)
    }

    class func setupFromJsonData(cycles: JSON, _ packs: JSON, language: String) -> Bool {
        cyclesByCode = [String: Cycle]()     // code -> cycle
        allCycles = [Int: Cycle]()           // position -> cycles
        packsByCode = [String: Pack]()       // code -> pack
        allPacks = [Pack]()
        
        let ok = cycles.validNrdbResponse && packs.validNrdbResponse
        if !ok {
            print("cards/packs invalid")
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

        /*
        let json = cycles
        for set in json.arrayValue {
            let cs = Pack()
            
            if let code = set["code"].string {
                cs.code = code
            } else {
                continue
            }
            
            if cs.setCode == DRAFT_SET_CODE {
                continue
            }
            
            if let name = set["name"].string {
                cs.name = name
            } else {
                continue
            }
            
            cs.settingsKey = "use_" + cs.setCode
            
            if let cycleNumber = set["cyclenumber"].int, let number = set["number"].int {
                if let cycle = cycleMap[cycleNumber] {
                    cs.cycle = cycle
                    cs.setNum = cycleNumber * 100 + number
                } else {
                    // new/unknown cycle -> make this the 7th/8th... pack of the last known cycle
                    cs.cycle = NRCycle.lastCycle
                    cs.setNum = NRCycle.lastCycle.rawValue * 100 + number + 6
                }
            }
            
            if let available = set["available"].string {
                cs.released = available.length > 0
            }
            
            allCardSets[cs.setNum] = cs
            code2name[cs.setCode] = cs.name
            code2number[cs.setCode] = cs.setNum
        }
        
        setGroups = [String]()
        setsPerGroup = [NRCycle: [Int]]()
        setsPerGroup[.CoreDeluxe] = [Int]()
        keysPerCycle = [NRCycle: [String]]()
        
        for key in cycleMap.keys.sort({ $0 < $1 }) {
            let cycle = cycleMap[key]!
            if cycle != .CoreDeluxe {
                setsPerGroup[cycle] = [Int]()
                let name = "Cycle #\(cycle.rawValue)"
                setGroups.append(name.localized())
            }
        }
        
        for cs in allCardSets.values
        {
            setsPerGroup[cs.cycle]!.append(cs.setNum)
            setsPerGroup[cs.cycle]!.sortInPlace { $0<$1 }
            
            if cs.cycle.rawValue > setGroups.count {
                let cycle = "Cycle #\(cs.cycle.rawValue)"
                setGroups.append(cycle.localized())
            }
            
            if cs.cycle != .CoreDeluxe {
                var arr = keysPerCycle[cs.cycle] ?? [String]()
                arr.append(cs.settingsKey)
                keysPerCycle[cs.cycle] = arr
            }
        }
        
        setGroups.insert("", atIndex:0)
        setGroups.insert("Core / Deluxe".localized(), atIndex:1)
        setsPerGroup[.None] = [Int]()
        assert(setGroups.count == setsPerGroup.count, "count mismatch")
        if setGroups.count != setsPerGroup.count {
            return false
        }
        
        // eliminate cycles where we have an enum value, but no data is available (yet)
        for cycle in cycleMap.values {
            let count = setsPerGroup[cycle]!.count
            if count == 0 {
                setGroups.removeAtIndex(cycle.rawValue+1)
                setsPerGroup.removeValueForKey(cycle)
            }
        }
        
        */
        NSUserDefaults.standardUserDefaults().registerDefaults(PackManager.settingsDefaults())
        
        return true
    }
    
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
    
    class func setNumForCode(code: String) -> Int {
        if let num = code2number[code] {
            return num
        }
        return 0
    }
    
    class func keysForCycle(cycle: NRCycle) -> [String]? {
        return keysPerCycle[cycle]
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
    
    class func clearDisabledPacks() {
        disabledPacks = nil
        enabledPacks = nil
    }

    class func allEnabledPacksForTableview() -> TableData {
        return TableData(values: [""])
        /*
        if (enabledSets == nil) {
            let disabledSetCodes = PackManager.disabledPackCodes()
            var sections = setGroups
            var setNames = [[String]]()
            var collapsed = [Bool]()
            
            let keys = setsPerGroup.keys.sort { $0.rawValue < $1.rawValue }
            
            for cycle in keys {
                var names = [String]()
                for setNum in setsPerGroup[cycle]! {
                    if setNum == 0 {
                        names.append(Constant.kANY)
                    }
                    else {
                        let cs = allCardSets[setNum]!
                        let setName = cs.name
                        if !disabledSetCodes.contains(cs.code) {
                            names.append(setName)
                        }
                    }
                }
                setNames.append(names)
                // collapse genesis, spin and luna cycle by default
                switch cycle {
                case .Genesis, .Spin, .Lunar: collapsed.append(true)
                default: collapsed.append(false)
                }
            }
            
            assert(collapsed.count == setNames.count)
            
            var i = 0
            while i < setNames.count {
                let arr = setNames[i]
                if arr.count == 0 {
                    setNames.removeAtIndex(i)
                    sections.removeAtIndex(i)
                    collapsed.removeAtIndex(i)
                }
                else {
                    i += 1
                }
            }
            enabledSets = TableData(sections:sections, andValues:setNames)
            enabledSets.collapsedSections = collapsed
        }
        
        return enabledSets
        */
    }

    class func allKnownPacksForTableview() -> TableData {
        var sections = [String]()
        var values = [[Pack]]()
        
        for (_, cycle) in allCycles.sort({ $0.0 < $1.0 }) {
            sections.append(cycle.name)
            
            let packs = allPacks.filter{ $0.cycleCode == cycle.code }
            values.append(packs)
        }
        
        return TableData(sections: sections, andValues: values)
    }
    
    class func packsUsedInDeck(deck: Deck) -> [String] {
        var setsUsed = [String: Int]()
        var cardsUsed = [String: Int]()
        var setNums = [String: Int]()
            
        for cc in deck.allCards {
            let code = cc.card.setCode
            let isCore = cc.card.isCore
            
            var used = setsUsed[code] ?? 1
            
            if isCore && cc.count > Int(cc.card.quantity) {
                let needed = Int(0.5 + Float(cc.count) / Float(cc.card.quantity))
                if needed > used {
                    used = needed
                }
            }
            
            setsUsed[code] = used
            if let num = code2number[code] {
                setNums[cc.card.setCode] = num
            }
            
            var cu = cardsUsed[code] ?? 0
            cu += cc.count
            cardsUsed[code] = cu
        }
            
        // NSLog(@"%@ %@", sets, setNums)
        
        let keys = setNums.keys
    
        let sorted = keys.sort { setNums[$0] < setNums[$1] }
        
        var result = [String]()
        for code in sorted {
            let used = cardsUsed[code]!
            let cards = used == 1 ? "Card".localized() : "Cards".localized()
            if code == CORE_SET_CODE {
                let needed = setsUsed[code]
                result.append(String(format:"%d×%@ - %d %@", needed!, code2name[code]!, used, cards))
            }
            else {
                result.append(String(format:"%@ - %d %@", code2name[code]!, used, cards))
            }
        }
        // NSLog(@"%@", result)
        return result
    }
    
    class func mostRecentPackUsedInDeck(deck: Deck) -> String {
        var maxIndex = 0
        
        for cc in deck.allCards {
            if let index = allPacks.indexOf({ $0.code == cc.card.setCode}) {
                maxIndex = max(index, maxIndex)
            }
        }
        
        return allPacks[maxIndex].name
    }
}

