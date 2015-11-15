//
//  CardSets.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

import Foundation

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
    
    static var allCardSets = [CardSet]()            // all known sets
    static var code2number = [String: Int]()        // map code -> number
    static var code2name = [String: String]()       // map code -> name
    static var setGroups = [String]()               // section names: 0=empty/any 1=core+deluxe, plus one for each cycle
    static var setsPerGroup = [[Int]]()             // one array per section, contains set numbers in that group
    
    // caches
    static var disabledSets: Set<String>?           // set of setCodes
    static var enabledSets: TableData!
    
    class func filename() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths[0]
        
        return supportDirectory.stringByAppendingPathComponent(SETS_FILENAME)
    }
    
    class func removeFiles() {
        let fileMgr = NSFileManager.defaultManager()
        try! fileMgr.removeItemAtPath(filename())
    
        CardManager.initialize()
    }
    
    class func setupFromFiles() -> Bool {
        let setsFile = filename()
        var ok = false
    
        let fileMgr = NSFileManager.defaultManager()
        if fileMgr.fileExistsAtPath(setsFile) {
            if let data = NSArray(contentsOfFile: setsFile) {
                ok = setupFromJsonData(data)
            }
        }
    
        //TODO: do we still need this?
        if (!ok) {
            // no file or botched data: use built-in fallback file
            let fallbackFile = NSBundle.mainBundle().pathForResource("builtin-sets", ofType:"plist");
            if let data = NSArray(contentsOfFile: fallbackFile!) {
                ok = setupFromJsonData(data)
            }
        }
            
        return ok;
    }
    
    class func setupFromNrdbApi(json: NSArray) -> Bool {
        let setsFile = filename()
        json.writeToFile(setsFile, atomically:true)
    
        AppDelegate.excludeFromBackup(setsFile)
    
        return setupFromJsonData(json)
    }

    
    class func setupFromJsonData(json: NSArray) -> Bool {
        var maxCycle = 0
        allCardSets = [CardSet]()
        for set in json as! [NSDictionary] {
            let cs = CardSet()
            
            cs.setCode = set["code"] as! String
            if cs.setCode == DRAFT_SET_CODE {
                continue
            }
            
            cs.name = set["name"] as! String
            cs.settingsKey = "use_" + cs.setCode
            
            let cycleNumber = set["cyclenumber"] as! Int
            
            if (cycleNumber % 2) == 0 { // even cycle number: this is a datapack
                if let cycle = NRCycle(rawValue: cycleNumber / 2) {
                    cs.cycle = cycle
                    maxCycle = max(cs.cycle.rawValue, maxCycle)
                    let number = set["number"] as! Int
                    cs.setNum = (cycleNumber-2) / 2 * 7 + 1 + number
                }
                else {
                    assert(false, "unknown cycle \(cycleNumber)")
                }
            }
            else { // odd cycle number: it is a core or deluxe
                cs.cycle = .CoreDeluxe;
                cs.setNum = (cycleNumber-1) / 2 * 7 + 1;
            }
            let available = set["available"] as! String
            cs.released = available.length > 0;
            
            allCardSets.append(cs)
            code2name[cs.setCode] = cs.name
            code2number[cs.setCode] = cs.setNum
        }
        
        allCardSets.sortInPlace {
            return $0.setNum < $1.setNum
        }
        
        setGroups = [String]()
        setsPerGroup = [[Int]]()
        setsPerGroup.append([ 0 ])
        for var i=0; i<=maxCycle; ++i {
            setsPerGroup.append([Int]())
        }
        
        for cs in allCardSets
        {
            setsPerGroup[cs.cycle.rawValue+1].append(cs.setNum)
            
            if cs.cycle.rawValue > setGroups.count {
                let cycle = "Cycle #\(cs.cycle.rawValue)"
                setGroups.append(cycle.localized())
            }
        }
        setGroups.insert("", atIndex:0)
        setGroups.insert("Core / Deluxe".localized(), atIndex:1)
        
        assert(setGroups.count == setsPerGroup.count, "count mismatch");
        
        NSUserDefaults.standardUserDefaults().registerDefaults(CardSets.settingsDefaults())
        return true;
    }
    
    class func setsAvailable() -> Bool {
        return allCardSets.count > 0
    }
    
    class func nameForKey(key: String) -> String? {
        if let index = allCardSets.indexOf({$0.settingsKey == key}) {
            return allCardSets[index].name
        }
        return nil;
    }

    class func settingsDefaults() -> [String: Bool] {
        var defaults = [String: Bool]()
        for cs in allCardSets {
            defaults[cs.settingsKey] = cs.released
        }
        return defaults;
    }
    
    class func setNumForCode(code: String) -> Int {
        if let num = code2number[code] {
            return num
        }
        return 0
    }
    
    class func disabledSetCodes() -> Set<String> {
        if disabledSets == nil {
            var disabled = Set<String>()
            let settings = NSUserDefaults.standardUserDefaults()
            for cs in allCardSets {
                if !settings.boolForKey(cs.settingsKey) {
                    disabled.insert(cs.setCode)
                }
            }
    
            if !settings.boolForKey(USE_DRAFT_IDS) {
                disabled.insert(DRAFT_SET_CODE)
            }
    
            disabledSets = disabled;
        }
    
        return disabledSets!
    }
    
    class func clearDisabledSets() {
        disabledSets = nil;
        enabledSets = nil;
    }

    class func allEnabledSetsForTableview() -> TableData {
        if (enabledSets == nil) {
            let disabledSetCodes = CardSets.disabledSetCodes()
            var sections = setGroups
            var setNames = [[String]]()
            
            for sets in setsPerGroup {
                var names = [String]()
                for setNum in sets {
                    if setNum == 0 {
                        names.append(kANY)
                    }
                    else if setNum <= allCardSets.count {
                        let cs = allCardSets[setNum-1]
                        let setName = cs.name
                        if setName != nil && !disabledSetCodes.contains(cs.setCode) {
                            names.append(setName)
                        }
                    }
                }
                setNames.append(names)
            }
            
            var i = 0
            while i < setNames.count {
                let arr = setNames[i]
                if arr.count == 0 {
                    setNames.removeAtIndex(i)
                    sections.removeAtIndex(i)
                }
                else {
                    ++i
                }
            }
            enabledSets = TableData(sections:sections, andValues:setNames)
            
            enabledSets.collapsedSections = [Bool]()
            for var i=0; i<enabledSets.sections.count; ++i {
                enabledSets.collapsedSections?.append(false)
            }
        }
        
        return enabledSets;
    }

    class func allKnownSetsForTableview() -> TableData {
        var sections = setGroups
        sections.removeAtIndex(0)
        
        var knownSets = [[CardSet]]()
        for setNumbers in setsPerGroup {
            var sets = [CardSet]()
            for setNum in setNumbers {
                if setNum == 0 {
                    continue
                }
                
                let cs = allCardSets[setNum-1]
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
                let needed = Int(0.5 + Float(cc.count) / Float(cc.card.quantity));
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
            
        // NSLog(@"%@ %@", sets, setNums);
        
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
        // NSLog(@"%@", result);
        return result;
    }
    
    class func mostRecentSetUsedInDeck(deck: Deck) -> String {
        var maxRelease = 0;
        
        for cc in deck.allCards {
            if let rel = code2number[cc.card.setCode] {
                maxRelease = max(maxRelease, rel)
            }
        }
        
        for cs in allCardSets {
            if cs.setNum == maxRelease
            {
                return cs.name
            }
        }
        return "?"
    }
}

