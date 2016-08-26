//
//  PrebuiltManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.08.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import SwiftyJSON

class Prebuilt: NSObject {
    var name = ""
    var settingsKey = ""
    var cards = [CardCounter]()
}

class PrebuiltManager: NSObject {
    
    static var allPrebuilts = [Prebuilt]()
    
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

