//
//  Card.swift
//  NetDeck
//
//  Created by Gereon Steffens on 18.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import DTCoreText
import SwiftyJSON

@objc class Card: NSObject {
    
    // identities we need to handle
    static let CUSTOM_BIOTICS           = "03002"    // no jinteki cards
    static let THE_PROFESSOR            = "03029"    // first copy of each program has influence 0
    static let ANDROMEDA                = "02083"    // 9 card starting hand
    static let APEX                     = "09029"    // no non-virtual resources
    
    // alliance cards with special influence rules
    static let MUMBA_TEMPLE             = "10018"    // 0 inf if <= 15 ice in deck
    static let MUSEUM_OF_HISTORY        = "10019"    // 0 inf if >= 50 cards in deck
    static let PAD_FACTORY              = "10038"    // 0 inf if 3 pad campaigns in deck
    static let MUMBAD_VIRTUAL_TOUR      = "10075"    // 0 inf if >= 7 assets in deck
    
    // alliance-based: 0 inf if >= non-alliance cards of same faction in deck
    static let PRODUCT_RECALL           = "10029"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let JEEVES_MODEL_BIOROID     = "10067"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let RAMAN_RAI                = "10068"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let HERITAGE_COMMITTEE       = "10013"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let SALEMS_HOSPITALITY       = "10071"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let IBRAHIM_SALEM            = "10109"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let EXECUTIVE_SEARCH_FIRM    = "10072"    // 0 inf if >= 6 non-alliance Weyland cards in deck

    
    static let ALLIANCE_6 = Set<String>([
        PRODUCT_RECALL, JEEVES_MODEL_BIOROID,
        RAMAN_RAI, HERITAGE_COMMITTEE,
        SALEMS_HOSPITALITY, IBRAHIM_SALEM,
        EXECUTIVE_SEARCH_FIRM ])
    
    static let PAD_CAMPAIGN             = "01109"    // needed for pad factory
    
    // "limit 1 per deck" cards
    static let DIRECTOR_HAAS_PET_PROJ   = "03004"
    static let PHILOTIC_ENTANGLEMENT    = "05006"
    static let UTOPIA_SHARD             = "06100"
    static let HADES_SHARD              = "06059"
    static let EDEN_SHARD               = "06020"
    static let EDEN_FRAGMENT            = "06030"
    static let HADES_FRAGMENT           = "06071"
    static let UTOPIA_FRAGMENT          = "06110"
    static let GOVERNMENT_TAKEOVER      = "07006"
    static let _15_MINUTES              = "09004"
    static let MAX_1_PER_DECK           = Set<String>([ DIRECTOR_HAAS_PET_PROJ, PHILOTIC_ENTANGLEMENT,
                                            UTOPIA_SHARD, UTOPIA_FRAGMENT, HADES_SHARD,
                                            HADES_FRAGMENT, EDEN_SHARD, EDEN_FRAGMENT,
                                            GOVERNMENT_TAKEOVER, _15_MINUTES ])
    
    private static let OCTGN_PREFIX = "bc0f047c-01b1-427f-a439-d451eda"
    
    // "most wanted" list
    static let CERBERUS_H1      = "06099"
    static let CLONE_CHIP       = "03038"
    static let DESPERADO        = "01024"
    static let PARASITE         = "01012"
    static let PREPAID_VOICEPAD = "04029"
    static let YOG_0            = "01014"
    
    static let ARCHITECT        = "06061"
    static let ASTROSCRIPT      = "01081"
    static let ELI_1            = "02110"
    static let NAPD_CONTRACT    = "04119"
    static let SANSAN_CITY_GRID = "01092"
    
    // MWL from Tournament Rules 3.0.2, valid from 2016-02-01 onwards
    static let MOST_WANTED_LIST = Set<String>([
        CERBERUS_H1, CLONE_CHIP, DESPERADO, PARASITE, PREPAID_VOICEPAD, YOG_0,
        ARCHITECT, ASTROSCRIPT, ELI_1, NAPD_CONTRACT, SANSAN_CITY_GRID ])
    
    private(set) var code: String!
    private(set) var name: String!
    private(set) var name_en: String!
    private(set) var alias: String?
    private(set) var text: String! = ""
    private(set) var flavor: String! = ""
    private(set) var type: NRCardType = .None
    private(set) var typeStr: String! = ""
    private(set) var subtype: String! = ""      // full subtype string like "Fracter - Icebreaker - AI"
    private(set) var subtypes = [String]()      // array of subtypes like [ "Fracter", "Icebreaker", "AI" ]
    private(set) var faction: NRFaction = .None
    private(set) var factionStr: String!
    private(set) var role: NRRole = .None
    private(set) var roleStr: String!
    private(set) var influenceLimit: Int = -1   // for id
    private(set) var minimumDecksize: Int = -1  // for id
    private(set) var baseLink: Int = -1         // for runner id
    private(set) var influence: Int = -1
    private(set) var mu: Int = -1
    private(set) var strength: Int = -1
    private(set) var cost: Int = -1
    private(set) var advancementCost: Int = -1   // agenda
    private(set) var agendaPoints: Int = -1      // agenda
    private(set) var trash: Int = -1
    private(set) var quantity: Int = -1          // number of cards in set
    private(set) var number: Int = -1            // card no. in set
    private(set) var setName: String!
    private(set) var setCode: String!
    private(set) var setNumber: Int = -1         // our own internal set number, for sorting by set release
    private(set) var unique: Bool = false
    private(set) var maxPerDeck: Int = -1        // how many may be in deck? currently either 1, 3 or 6
    private(set) var imageSrc: String?
    private(set) var ancurLink: String?
    private(set) var isAlliance: Bool = false
    private(set) var isVirtual: Bool = false
    private(set) var isCore: Bool = false       // card is from core set
    
    private static var multiIce = [String]()
    
    static let nullInstance = Card()
    
    class func null() -> Card {
        return nullInstance
    }
    
    var isNull: Bool {
        return self === Card.nullInstance
    }
    
    var isMostWanted: Bool {
        return Card.MOST_WANTED_LIST.contains(self.code)
    }
    
    // special for ICE: return primary subtype (Barrier, CG, Sentry, Trap, Mythic) or "Multi"
    var iceType: String? {
        assert(self.type == .Ice, "not an ice")
        
        if Card.multiIce.contains(self.code) {
            return "Multi".localized()
        }
        
        return self.subtypes.count == 0 ? "ICE".localized() : self.subtypes[0]
    }
    
    // special for Programs: return "Icebreaker" for icebreakers, "Program" for other programs
    var programType: String? {
        assert(self.type == .Program, "not a program")
        if self.strength != -1 {
            return self.subtypes[0]
        } else {
            return self.typeStr
        }
    }

    var factionColor: UIColor {
        return UIColor.colorWithRGB(self.factionHexColor)
    }
    
    var factionHexColor: UInt {
        assert(self.faction != .None)
        return Card.factionColors[self.faction]!
    }
    
    private var _attributedText: NSAttributedString?
    // html rendered
    var attributedText: NSAttributedString! {
        if self._attributedText == nil {
            let str = self.text.stringByReplacingOccurrencesOfString("\n", withString: "<br/>")
            let data = str.dataUsingEncoding(NSUTF8StringEncoding)
            self._attributedText = NSAttributedString(HTMLData: data, options: Card.coreTextOptions, documentAttributes: nil)
            if self._attributedText == nil {
                self._attributedText = NSAttributedString(string: "")
            }
        }
        return self._attributedText!
    }

    var octgnCode: String {
        return Card.OCTGN_PREFIX + self.code
    }
    
    var cropY: Double {
        assert(self.type != .None)
        return Card.cropValues[self.type]!
    }
    
    // how many copies owned
    var owned: Int {
        if self.isCore {
            let cores = NSUserDefaults.standardUserDefaults().integerForKey(SettingsKeys.NUM_CORES)
            return cores * self.quantity
        }
        let disabledSets = CardSets.disabledSetCodes()
        if disabledSets.contains(self.setCode) {
            return 0
        }
        return self.quantity
    }
    
    class func cardFromJson(json: JSON) -> Card? {
        let c = Card()
        
        c.code = json["code"].stringValue
        c.name = json["title"].stringValue
        c.name_en = c.name
        
        c.factionStr = json["faction"].stringValue
        let factionCode = json["faction_code"].stringValue
        c.faction = Faction.faction(factionCode)
        assert(c.faction != .None, "no faction for \(c.code)")
        if c.faction == .None {
            print("missing faction: \(factionCode) \(c.name)")
            return nil
        }
        
        c.roleStr = json["side"].stringValue
        let roleCode = json["side_code"].stringValue
        
        c.role = Codes.roleForCode(roleCode)
        assert(c.role != .None, "no role for \(c.code)")
        if c.role == .None {
            print("missing role: \(roleCode) \(c.name)")
            return nil
        }
        
        c.typeStr = json["type"].stringValue
        let typeCode = json["type_code"].stringValue
        c.type = CardType.type(typeCode)
        // assert(c.type != .None, "no type for \(c.code), \(typeCode)")
        if c.type == .None {
            print("missing type: \(typeCode) \(c.name)")
            return nil
        }
        
        if c.type == .Identity {
            c.name = c.shortIdentityName(c.name, forRole: c.role, andFaction: c.factionStr)
        }
        // remove the "consortium" from weyland's name
        if c.faction == .Weyland {
            c.factionStr = "Weyland"
        }
        
        if let text = json["text"].string {
            c.text = text
        }
        if let flavor = json["flavor"].string {
            c.flavor = flavor
        }
        
        c.setName = json["setname"].stringValue
        c.setCode = json["set_code"].stringValue
        if c.setCode == nil {
            c.setCode = CardSets.UNKNOWN_SET
            c.setName = CardSets.UNKNOWN_SET
        }
        if c.setCode == CardSets.DRAFT_SET_CODE {
            c.faction = .Neutral
        }
        
        c.setNumber = CardSets.setNumForCode(c.setCode)
        c.isCore = c.setCode.lowercaseString == CardSets.CORE_SET_CODE
        
        if let subtype = json["subtype"].string {
            c.subtype = subtype
        }
        if c.subtype.length > 0 {
            let split = self.subtypeSplit(c.subtype)
            c.subtype = split.subtype
            c.subtypes = split.subtypes
        }
        
        c.number = json["number"].int ?? -1
        c.quantity = json["quantity"].int ?? -1
        c.unique = json["uniqueness"].boolValue
        
        if c.type == .Identity {
            c.influenceLimit = json["influencelimit"].int ?? -1
            c.minimumDecksize = json["minimumdecksize"].int ?? -1
            c.baseLink = json["baselink"].int ?? -1
        }
        if c.type == .Agenda {
            c.advancementCost = json["advancementcost"].int ?? -1
            c.agendaPoints = json["agendapoints"].int ?? -1
        }
        
        c.mu = json["memoryunits"].int ?? -1
        c.strength = json["strength"].int ?? -1
        c.cost = json["cost"].int ?? -1
        c.influence = json["factioncost"].int ?? -1
        c.trash = json["trash"].int ?? -1
        
        c.imageSrc = json["imagesrc"].string
        if c.imageSrc?.length > 0 {
            let host = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_HOST)
            c.imageSrc = "http://" + host! + c.imageSrc!
        }
        
        if c.imageSrc?.length == 0 {
            c.imageSrc = nil
        }
        
        c.maxPerDeck = json["limited"].int ?? -1
        if Card.MAX_1_PER_DECK.contains(c.code) || c.type == .Identity {
            c.maxPerDeck = 1
        }
        
        c.ancurLink = json["ancurLink"].string
        if c.ancurLink?.length == 0 {
            c.ancurLink = nil
        }
        
        return c
    }
    
    private class func subtypeSplit(subtype: String) -> (subtype: String, subtypes: [String]) {
        var s = subtype.stringByReplacingOccurrencesOfString("G-Mod", withString: "G-mod")
        s = subtype.stringByReplacingOccurrencesOfString(" – ", withString: " - ") // fix dashes in german subtypes
        let subtypes = s.componentsSeparatedByString(" - ")
        return (subtype, subtypes)
    }
    
    // NB: not part of the public API!
    func setAlliance(subtype: String) {
        self.isAlliance = subtype.lowercaseString.containsString("alliance")
    }
    
    func setVirtual(subtype: String) {
        self.isVirtual = subtype.lowercaseString.containsString("virtual")
    }
    
    func setMultiIce(subtype: String) {
        if self.type == .Ice {
            let (_, subtypes) = Card.subtypeSplit(subtype)
            let barrier = subtypes.contains("Barrier")
            let sentry = subtypes.contains("Sentry")
            let codeGate = subtypes.contains("Code Gate")
            if barrier && sentry && codeGate {
                print("multi: \(self.name)")
                Card.multiIce.append(self.code)
            }
        }
    }
    
    func setNameEn(nameEn: String) {
        self.name_en = nameEn
    }
    
    func setCardAlias(alias: String) {
        self.alias = alias
    }
    
    // manipulate identity name
    func shortIdentityName(name: String, forRole: NRRole, andFaction faction: String) -> String {
        if let colon = name.rangeOfString(": ") {
            // runner: remove stuff after the colon ("Andromeda: Disposessed Ristie" becomes "Andromeda")
            if role == .Runner {
                return name.substringToIndex(colon.startIndex)
            }
        
            // corp: if faction name is part of the title, remove it ("NBN: The World is Yours*" becomes "The World is Yours*")
            // otherwise, remove stuff after the colon ("Harmony Medtech: Biomedical Pioneer" becomes "Harmony Medtech")
            if role == .Corp {
                if let range = name.rangeOfString(faction + ": ") {
                    return name.substringFromIndex(range.endIndex)
                } else {
                    return name.substringToIndex(colon.startIndex)
                }
            }
        }
        return name
    }
    
    private static let factionColors: [NRFaction: UInt] = [
        .Jinteki:      0x940c00,
        .NBN:          0xd7a32d,
        .Weyland:      0x2d7868,
        .HaasBioroid:  0x6b2b8a,
        .Shaper:       0x6ab545,
        .Criminal:     0x4f67b0,
        .Anarch:       0xf47c28,
        .Adam:         0xae9543,
        .Apex:         0xa8403d,
        .SunnyLebeau:  0x776e6f,
        .Neutral:      0x000000
    ]
    
    private static let cropValues: [NRCardType: Double] = [
        .Agenda: 15,
        .Asset: 20,
        .Event: 10,
        .Identity: 12,
        .Operation: 10,
        .Hardware: 18,
        .Ice: 209,
        .Program: 8,
        .Resource: 11,
        .Upgrade: 22
    ]
    
    static let fontFamily = UIFont.systemFontOfSize(13).familyName
    static let coreTextOptions = [
        DTUseiOS6Attributes: true,
        DTDefaultFontFamily: NSString(string: fontFamily),
        DTDefaultFontSize: 13
    ]
    
    override var hashValue: Int {
        return code.hashValue
    }
}

func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.code == rhs.code
}
