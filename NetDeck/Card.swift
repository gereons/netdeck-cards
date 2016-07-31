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
    static let MUMBAD_VIRTUAL_TOUR      = "10076"    // 0 inf if >= 7 assets in deck
    
    // alliance-based: 0 inf if >= 6 non-alliance cards of same faction in deck
    static let PRODUCT_RECALL           = "10029"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let JEEVES_MODEL_BIOROID     = "10067"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let RAMAN_RAI                = "10068"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let HERITAGE_COMMITTEE       = "10013"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let SALEMS_HOSPITALITY       = "10071"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let IBRAHIM_SALEM            = "10109"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let EXECUTIVE_SEARCH_FIRM    = "10072"    // 0 inf if >= 6 non-alliance Weyland cards in deck
    static let CONSULTING_VISIT         = "10094"    // 0 inf if >= 6 non-alliance Weyland cards in deck

    static let ALLIANCE_6 = Set<String>([
        PRODUCT_RECALL, JEEVES_MODEL_BIOROID,
        RAMAN_RAI, HERITAGE_COMMITTEE,
        SALEMS_HOSPITALITY, IBRAHIM_SALEM,
        EXECUTIVE_SEARCH_FIRM, CONSULTING_VISIT ])
    
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
    static let REBIRTH                  = "10083"
    static let BLACK_FILE               = "10099"
    static let MAX_1_PER_DECK           = Set<String>([ DIRECTOR_HAAS_PET_PROJ, PHILOTIC_ENTANGLEMENT,
                                            UTOPIA_SHARD, UTOPIA_FRAGMENT, HADES_SHARD,
                                            HADES_FRAGMENT, EDEN_SHARD, EDEN_FRAGMENT,
                                            GOVERNMENT_TAKEOVER, _15_MINUTES, REBIRTH, BLACK_FILE ])
    
    static let OCTGN_PREFIX = "bc0f047c-01b1-427f-a439-d451eda"
    
    // "most wanted" list
    static let CERBERUS_H1      = "06099"
    static let CLONE_CHIP       = "03038"
    static let DESPERADO        = "01024"
    static let PARASITE         = "01012"
    static let PREPAID_VOICEPAD = "04029"
    static let YOG_0            = "01014"
    static let D4V1D            = "06033"
    static let FAUST            = "08061"
    static let WYLDSIDE         = "01016"
    
    static let ARCHITECT        = "06061"
    static let ASTROSCRIPT      = "01081"
    static let ELI_1            = "02110"
    static let NAPD_CONTRACT    = "04119"
    static let SANSAN_CITY_GRID = "01092"
    static let BREAKING_NEWS    = "01082"
    
    
    private struct MWL {
        let code: String
        let cards: Set<String>
    }
    
    private static let MostWantedLists: [NRMWL: MWL] = [
        // MWL introduced in Tournament Rules 3.0.2, valid from 2016-02-01 until 2016-07-31
        .v1_0: MWL(code: "NAPD_MWL_1.0", cards: Set<String>([
            CERBERUS_H1, CLONE_CHIP, DESPERADO, PARASITE, PREPAID_VOICEPAD, YOG_0,
            ARCHITECT, ASTROSCRIPT, ELI_1, NAPD_CONTRACT, SANSAN_CITY_GRID ])),
        
        // MWL introduced in Tournament Regulations v1.1, valid from 2016-08-01 onwards
        .v1_1: MWL(code: "NAPD_MWL_1.1", cards: Set<String>([
            CERBERUS_H1, CLONE_CHIP, D4V1D, DESPERADO, FAUST, PARASITE, PREPAID_VOICEPAD, WYLDSIDE, YOG_0,
            ARCHITECT, BREAKING_NEWS, ELI_1, MUMBA_TEMPLE, NAPD_CONTRACT, SANSAN_CITY_GRID ]))
    ]
    
    private(set) static var fullNames = [String: String]()
    private static let X = -2                   // for strength/cost "X". *MUST* be less than -1!
    
    private(set) var code = ""
    private(set) var name = ""                  // localized name of card, used for display
    private(set) var englishName = ""           // english name of card, used for searches
    private(set) var alias: String?
    private(set) var text = ""
    private(set) var flavor = ""
    private(set) var type = NRCardType.None
    private(set) var subtype = ""               // full subtype string like "Fracter - Icebreaker - AI"
    private(set) var subtypes = [String]()      // array of subtypes like [ "Fracter", "Icebreaker", "AI" ]
    private(set) var faction = NRFaction.None
    private(set) var role = NRRole.None
    private(set) var influenceLimit = -1        // for id
    private(set) var minimumDecksize = -1       // for id
    private(set) var baseLink = -1              // for runner id
    private(set) var influence = -1
    private(set) var mu = -1
    private(set) var strength = -1
    private(set) var cost = -1
    private(set) var advancementCost = -1       // agenda
    private(set) var agendaPoints = -1          // agenda
    private(set) var trash = -1
    private(set) var quantity = -1              // number of cards in set
    private(set) var number = -1                // card no. in set
    private(set) var packCode = ""
    private(set) var packNumber = -1            // our own internal pack number, for sorting by pack release
    private(set) var unique = false
    private(set) var maxPerDeck = -1            // how many may be in deck? currently either 1, 3 or 6
    
    private(set) var isAlliance = false
    private(set) var isVirtual = false
    private(set) var isCore = false             // card is from core set
    
    private static var multiIce = [String]()
    
    private static let nullInstance = Card()
    
    private var factionCode = ""
    private var typeCode = ""
    
    var typeStr: String { return Translation.forTerm(self.typeCode, language: Card.currentLanguage) }
    var factionStr: String { return Translation.forTerm(self.factionCode, language: Card.currentLanguage) }

    var packName: String {
        return PackManager.packsByCode[self.packCode]?.name ?? ""
    }
    
    var imageSrc: String {
        return Card.imgSrcTemplate
            .stringByReplacingOccurrencesOfString("{locale}", withString: Card.currentLanguage)
            .stringByReplacingOccurrencesOfString("{code}", withString: self.code)
    }
    
    var ancurLink: String {
        let wikiName = self.englishName
            .stringByReplacingOccurrencesOfString(" ", withString: "_")
            .stringByAddingPercentEncodingWithAllowedCharacters(.URLPathAllowedCharacterSet()) ?? self.englishName
        return "http://ancur.wikia.com/wiki/" + wikiName
    }
    
    var nrdbLink: String {
        return "https://netrunnerdb.com/" + Card.currentLanguage + "/card/" + self.code
    }
    
    static private var imgSrcTemplate = ""
    static private var currentLanguage = ""
    
    class func null() -> Card {
        return nullInstance
    }
    
    var isNull: Bool {
        return self === Card.nullInstance
    }
    
    func isMostWanted(mwl: NRMWL) -> Bool {
        guard mwl != .None else { return false }
        let cards = Card.MostWantedLists[mwl]!.cards
        return cards.contains(self.code)
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
        if self.strength >= 0 || self.strength == Card.X {
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
        let disabledPacks = PackManager.disabledPackCodes()
        if disabledPacks.contains(self.packCode) {
            return 0
        }
        return self.quantity
    }
    
    var isValid: Bool {
        return self.role != .None && self.faction != .None && self.type != .None
    }
    
    var costString: String {
        return xStringify(self.cost)
    }
    
    var strengthString: String {
        return xStringify(self.strength)
    }
    
    private func xStringify(x: Int) -> String {
        switch x {
        case -1: return ""
        case Card.X: return "X"
        default: return "\(x)"
        }
    }
    
    class func cardsFromJson(json: JSON, language: String) -> [Card] {
        var cards = [Card]()
        imgSrcTemplate = json["imageUrlTemplate"].stringValue
        currentLanguage = language
        for cardJson in json["data"].arrayValue {
            let card = Card.cardFromJson(cardJson, language: language)
            cards.append(card)
        }
        return cards
    }
    
    private class func cardFromJson(json: JSON, language: String) -> Card {
        let c = Card()
        
        c.code = json["code"].stringValue
        c.englishName = json["title"].stringValue
        c.name = json.localized("title", language)
        
        c.factionCode = json["faction_code"].stringValue
        c.faction = Codes.factionForCode(c.factionCode)
        
        let roleCode = json["side_code"].stringValue
        c.role = Codes.roleForCode(roleCode)
        
        c.typeCode = json["type_code"].stringValue
        c.type = Codes.typeForCode(c.typeCode)
        
        if c.type == .Identity {
            Card.fullNames[c.code] = c.englishName
            c.name = c.shortIdentityName(c.name, forRole: c.role, andFaction: c.factionStr)
        }
        
        c.text = json.localized("text", language)
        c.flavor = json.localized("flavor", language)
        
        c.packCode = json["pack_code"].stringValue
        if c.packCode == "" {
            c.packCode = PackManager.UNKNOWN_SET
            c.packCode = PackManager.UNKNOWN_SET
        }
        if c.packCode == PackManager.DRAFT_SET_CODE {
            c.faction = .Neutral
        }
        
        c.packNumber = PackManager.packNumberForCode(c.packCode)
        c.isCore = c.packCode == PackManager.CORE_SET_CODE
        
        c.subtype = json.localized("keywords", language)
        if c.subtype.length > 0 {
            let split = self.subtypeSplit(c.subtype)
            c.subtype = split.subtype
            c.subtypes = split.subtypes
        }
        
        c.number = json["position"].int ?? -1
        c.quantity = json["quantity"].int ?? -1
        c.unique = json["uniqueness"].boolValue
        
        if c.type == .Identity {
            c.influenceLimit = json["influence_limit"].int ?? -1
            c.minimumDecksize = json["minimum_deck_size"].int ?? -1
            c.baseLink = json["base_link"].int ?? -1
        }
        if c.type == .Agenda {
            c.advancementCost = json["advancement_cost"].int ?? -1
            c.agendaPoints = json["agenda_points"].int ?? -1
        }
        
        c.mu = json["memory_cost"].int ?? -1
        
        if json["strength"].stringValue == "X" {
            c.strength = Card.X
        } else {
            c.strength = json["strength"].int ?? -1
        }
        
        if json["cost"].stringValue == "X" {
            c.cost = Card.X
        } else {
            c.cost = json["cost"].int ?? -1
        }
        
        c.influence = json["faction_cost"].int ?? -1
        c.trash = json["trash_cost"].int ?? -1
        
        c.maxPerDeck = json["deck_limit"].int ?? -1
        if Card.MAX_1_PER_DECK.contains(c.code) || c.type == .Identity {
            c.maxPerDeck = 1
        }
        
        c.isAlliance = c.subtype.lowercaseString.containsString("alliance")
        c.isVirtual = c.subtype.lowercaseString.containsString("virtual")
        if c.type == .Ice {
            let barrier = c.subtypes.contains("Barrier")
            let sentry = c.subtypes.contains("Sentry")
            let codeGate = c.subtypes.contains("Code Gate")
            if barrier && sentry && codeGate {
                // print("multi: \(c.name)")
                Card.multiIce.append(c.code)
            }
        }
        
        return c
    }
    
//    func setLocalPropertiesFrom(localCard: Card) {
//        self.name = localCard.name
//        self.typeStr = localCard.typeStr
//        self.subtype = localCard.subtype
//        self.subtypes = localCard.subtypes
//        self.factionStr = localCard.factionStr
//        self.text = localCard.text
//        self.flavor = localCard.flavor
//        if let localImg = localCard.imageSrc {
//            self.imageSrc = localImg
//        }
//    }
    
    private class func subtypeSplit(subtype: String) -> (subtype: String, subtypes: [String]) {
        let s = subtype.stringByReplacingOccurrencesOfString("G-Mod", withString: "G-mod")
        let t = s.stringByReplacingOccurrencesOfString(" – ", withString: " - ") // fix dashes in german subtypes
        if s != t {
            print("dashes found!")
        }
        var subtypes = t.componentsSeparatedByString(" - ")
        for i in 0 ..< subtypes.count {
            subtypes[i] = subtypes[i].trim()
        }
        return (subtype, subtypes)
    }
    
    func setCardAlias(alias: String) {
        self.alias = alias
    }
    
    // manipulate identity name
    func shortIdentityName(name: String, forRole role: NRRole, andFaction faction: String) -> String {
        if let colon = name.rangeOfString(": ") {
            // runner: remove stuff after the colon ("Andromeda: Disposessed Ristie" becomes "Andromeda")
            if role == .Runner {
                return name.substringToIndex(colon.startIndex)
            }
        
            // corp: if faction name is part of the title, remove it ("NBN: The World is Yours*" becomes "The World is Yours*")
            // otherwise, remove stuff after the colon ("Harmony Medtech: Biomedical Pioneer" becomes "Harmony Medtech")
            if role == .Corp {
                if name.hasPrefix(faction) {
                    return name.substringFromIndex(colon.startIndex.advancedBy(2)) // bump to after the ": "
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
