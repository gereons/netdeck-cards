//
//  CardSets.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import SwiftyJSON

@objc class CardSet: NSObject {
    var name: String!
    var setNum: Int = 0             // unique number //TODO: why not cycle*100+number?
    var setCode: String!
    var settingsKey: String!
    var cycle: NRCycle = .None
    var released = false
}

@objc class CardSets: NSObject {
    static let DRAFT_SET_CODE = "draft"
    static let CORE_SET_CODE = "core"
    static let UNKNOWN_SET = "unknown"
    static let setsFilename = "nrsets.json"
    
    static var allCardSets = [Int: CardSet]()       // all known sets: map setNum: cardset
    static var code2number = [String: Int]()        // map code -> number
    static var code2name = [String: String]()       // map code -> name
    static var setGroups = [String]()               // section names: 0=empty/any 1=core+deluxe, plus one for each cycle
    static var setsPerGroup = [NRCycle: [Int]]()    // one array per cycle, contains set numbers in that group
    static var keysPerCycle = [NRCycle: [String]]()    // "use_xyz" settings keys, per cycle
    
    // caches
    static var disabledSets: Set<String>?           // set of setCodes
    static var enabledSets: TableData!
    
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
    
    class func pathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.stringByAppendingPathComponent(CardSets.setsFilename)
    }
    
    class func removeFiles() {
        let fileMgr = NSFileManager.defaultManager()
        _ = try? fileMgr.removeItemAtPath(pathname())
    
        CardManager.initialize()
    }
    
    class func setupFromFiles() -> Bool {
        let setsFile = pathname()
    
        let fileMgr = NSFileManager.defaultManager()
        if fileMgr.fileExistsAtPath(setsFile) {
            if let array = NSArray(contentsOfFile: setsFile) {
                let json = JSON(array)
                return setupFromJsonData(json)
            } else if let str = try? NSString(contentsOfFile: setsFile, encoding: NSUTF8StringEncoding) {
                let json = JSON.parse(str as String)
                return setupFromJsonData(json)
            }
        }
                
        return false
    }
    
    class func setupFromNrdbApi(json: JSON) -> Bool {
        let setsFile = pathname()
        if let data = try? json.rawData() {
            data.writeToFile(setsFile, atomically:true)
        }
    
        AppDelegate.excludeFromBackup(setsFile)
    
        return setupFromJsonData(json)
    }

    class func setupFromJsonData(json: JSON) -> Bool {
        allCardSets = [Int: CardSet]()

        for set in json.arrayValue {
            let cs = CardSet()
            
            if let code = set["code"].string {
                cs.setCode = code
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
                    // new/unknown cycle
                    cs.cycle = NRCycle.lastCycle
                    cs.setNum = (NRCycle.lastCycle.rawValue + 1) * 100 + number
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
        
        NSUserDefaults.standardUserDefaults().registerDefaults(CardSets.settingsDefaults())
        return true
    }
    
    class func setsAvailable() -> Bool {
        return allCardSets.count > 0
    }
    
    class func nameForKey(key: String) -> String? {
        let sets = allCardSets.values
        if let index = sets.indexOf({$0.settingsKey == key}) {
            return sets[index].name
        }
        return nil
    }

    class func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        for cs in allCardSets.values {
            defaults[cs.settingsKey] = cs.released
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
    
    class func disabledSetCodes() -> Set<String> {
        if disabledSets == nil {
            var disabled = Set<String>()
            let settings = NSUserDefaults.standardUserDefaults()
            for cs in allCardSets.values {
                if !settings.boolForKey(cs.settingsKey) {
                    disabled.insert(cs.setCode)
                }
            }
    
            if !settings.boolForKey(SettingsKeys.USE_DRAFT_IDS) {
                disabled.insert(DRAFT_SET_CODE)
            }
    
            disabledSets = disabled
        }
    
        return disabledSets!
    }
    
    class func clearDisabledSets() {
        disabledSets = nil
        enabledSets = nil
    }

    class func allEnabledSetsForTableview() -> TableData {
        if (enabledSets == nil) {
            let disabledSetCodes = CardSets.disabledSetCodes()
            var sections = setGroups
            var setNames = [[String]]()
            var collapsed = [Bool]()
            
            let keys = setsPerGroup.keys.sort { $0.rawValue < $1.rawValue }
            
            for cycle in keys {
                var names = [String]()
                for setNum in setsPerGroup[cycle]! {
                    if setNum == 0 {
                        names.append(kANY)
                    }
                    else {
                        let cs = allCardSets[setNum]!
                        let setName = cs.name
                        if setName != nil && !disabledSetCodes.contains(cs.setCode) {
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
    }

    class func allKnownSetsForTableview() -> TableData {
        var sections = setGroups
        sections.removeAtIndex(0)
        
        var knownSets = [[CardSet]]()

        let cycles = setsPerGroup.keys.sort { $0.rawValue < $1.rawValue }
        for cycle in cycles {
            let setNumbers = setsPerGroup[cycle]!
            var sets = [CardSet]()
            for setNum in setNumbers {
                if setNum == 0 {
                    continue
                }
                
                let cs = allCardSets[setNum]!
                if cs.name != nil {
                    sets.append(cs)
                }
            }
            if sets.count > 0 {
                knownSets.append(sets)
            }
        }
        
        assert(sections.count == knownSets.count, "count mismatch")
        
        return TableData(sections:sections, andValues:knownSets)
    }
    
    class func setsUsedInDeck(deck: Deck) -> [String] {
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
    
    class func mostRecentSetUsedInDeck(deck: Deck) -> String {
        var maxRelease = 0
        
        for cc in deck.allCards {
            if let rel = code2number[cc.card.setCode] {
                maxRelease = max(maxRelease, rel)
            }
        }
        
        for cs in allCardSets.values {
            if cs.setNum == maxRelease {
                return cs.name
            }
        }
        return "?"
    }
}

