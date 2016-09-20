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

class Card: NSObject {
    
    // identities we need to handle
    static let customBiotics            = "03002"    // no jinteki cards
    static let theProfessor             = "03029"    // first copy of each program has influence 0
    static let andromeda                = "02083"    // 9 card starting hand
    static let apex                     = "09029"    // no non-virtual resources
    
    // alliance cards with special influence rules
    static let mumbaTemple              = "10018"    // 0 inf if <= 15 ice in deck
    static let museumOfHistory          = "10019"    // 0 inf if >= 50 cards in deck
    static let padFactory               = "10038"    // 0 inf if 3 pad campaigns in deck
    static let mumbadVirtualTour        = "10076"    // 0 inf if >= 7 assets in deck
    
    // alliance-based: 0 inf if >= 6 non-alliance cards of same faction in deck
    static let productRecall            = "10029"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let jeevesModelBioroid       = "10067"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let ramanRai                 = "10068"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let heritageCommittee        = "10013"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let salemsHospitality        = "10071"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let ibrahimSalem             = "10109"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let executiveSearchFirm      = "10072"    // 0 inf if >= 6 non-alliance Weyland cards in deck
    static let consultingVisit          = "10094"    // 0 inf if >= 6 non-alliance Weyland cards in deck

    static let alliance6 = Set<String>([
        productRecall, jeevesModelBioroid,
        ramanRai, heritageCommittee,
        salemsHospitality, ibrahimSalem,
        executiveSearchFirm, consultingVisit ])
    
    static let padCampaign              = "01109"    // needed for pad factory
    
    // "limit 1 per deck" cards
    static let directorHaasPetProject   = "03004"
    static let philoticEntanglement     = "05006"
    static let utopiaShard              = "06100"
    static let hadesShard               = "06059"
    static let edenShard                = "06020"
    static let edenFragment             = "06030"
    static let hadesFragment            = "06071"
    static let utopiaFragment           = "06110"
    static let governmentTakeover       = "07006"
    static let _15minutes               = "09004"
    static let rebirth                  = "10083"
    static let blackFile                = "10099"
    static let max1perDeck              = Set<String>([ directorHaasPetProject, philoticEntanglement,
                                            utopiaShard, utopiaFragment, hadesShard,
                                            hadesFragment, edenShard, edenFragment,
                                            governmentTakeover, _15minutes, rebirth, blackFile, astroscript ])
    
    static let octgnPrefix = "bc0f047c-01b1-427f-a439-d451eda"
    
    // "most wanted" list
    static let cerberusH1       = "06099"
    static let cloneChip        = "03038"
    static let desperado        = "01024"
    static let parasite         = "01012"
    static let prepaidVoicepad  = "04029"
    static let yog_0            = "01014"
    static let d4v1d            = "06033"
    static let faust            = "08061"
    static let wyldside         = "01016"
    
    static let architect        = "06061"
    static let astroscript      = "01081"
    static let eli_1            = "02110"
    static let napdContract     = "04119"
    static let sansanCityGrid   = "01092"
    static let breakingNews     = "01082"
    
    fileprivate static let MostWantedLists: [NRMWL: Set<String>] = [
        // MWL v1.0, introduced in Tournament Rules 3.0.2, valid from 2016-02-01 until 2016-07-31
        .v1_0: Set<String>([
            cerberusH1, cloneChip, desperado, parasite, prepaidVoicepad, yog_0,
            architect, astroscript, eli_1, napdContract, sansanCityGrid ]),
        
        // MWL v1.1, introduced in Tournament Regulations v1.1, valid from 2016-08-01 onwards
        .v1_1: Set<String>([
            cerberusH1, cloneChip, d4v1d, desperado, faust, parasite, prepaidVoicepad, wyldside, yog_0,
            architect, breakingNews, eli_1, mumbaTemple, napdContract, sansanCityGrid ])
    ]
    
    fileprivate(set) static var fullNames = [String: String]()
    fileprivate static let X = -2                   // for strength/cost "X". *MUST* be less than -1!
    
    fileprivate(set) var code = ""
    fileprivate(set) var name = ""                  // localized name of card, used for display
    fileprivate(set) var englishName = ""           // english name of card, used for searches
    fileprivate(set) var alias: String?
    fileprivate(set) var text = ""
    fileprivate(set) var flavor = ""
    fileprivate(set) var type = NRCardType.none
    fileprivate(set) var subtype = ""               // full subtype string like "Fracter - Icebreaker - AI"
    fileprivate(set) var subtypes = [String]()      // array of subtypes like [ "Fracter", "Icebreaker", "AI" ]
    fileprivate(set) var faction = NRFaction.none
    fileprivate(set) var role = NRRole.none
    fileprivate(set) var influenceLimit = -1        // for id
    fileprivate(set) var minimumDecksize = -1       // for id
    fileprivate(set) var baseLink = -1              // for runner id
    fileprivate(set) var influence = -1
    fileprivate(set) var mu = -1
    fileprivate(set) var strength = -1
    fileprivate(set) var cost = -1
    fileprivate(set) var advancementCost = -1       // agenda
    fileprivate(set) var agendaPoints = -1          // agenda
    fileprivate(set) var trash = -1
    fileprivate(set) var quantity = -1              // number of cards in set
    fileprivate(set) var number = -1                // card no. in set
    fileprivate(set) var packCode = ""
    fileprivate(set) var packNumber = -1            // our own internal pack number, for sorting by pack release
    fileprivate(set) var unique = false
    fileprivate(set) var maxPerDeck = -1            // how many may be in deck? currently either 1, 3 or 6
    
    fileprivate(set) var isAlliance = false
    fileprivate(set) var isVirtual = false
    fileprivate(set) var isCore = false             // card is from core set
    
    fileprivate static var multiIce = [String]()
    
    fileprivate static let nullInstance = Card()
    
    fileprivate var factionCode = ""
    fileprivate var typeCode = ""
    
    var typeStr: String { return Translation.forTerm(self.typeCode, language: Card.currentLanguage) }
    var factionStr: String { return Translation.forTerm(self.factionCode, language: Card.currentLanguage) }

    var packName: String {
        return PackManager.packsByCode[self.packCode]?.name ?? ""
    }
    
    var imageSrc: String {
        return Card.imgSrcTemplate
            .replacingOccurrences(of: "{locale}", with: Card.currentLanguage)
            .replacingOccurrences(of: "{code}", with: self.code)
    }
    
    var ancurLink: String {
        let wikiName = self.englishName
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self.englishName
        return "http://ancur.wikia.com/wiki/" + wikiName
    }
    
    var nrdbLink: String {
        return "https://netrunnerdb.com/" + Card.currentLanguage + "/card/" + self.code
    }
    
    static fileprivate var imgSrcTemplate = ""
    static fileprivate var currentLanguage = ""
    
    class func null() -> Card {
        return nullInstance
    }
    
    var isNull: Bool {
        return self === Card.nullInstance
    }
    
    func isMostWanted(_ mwl: NRMWL) -> Bool {
        guard mwl != .none else { return false }
        let cards = Card.MostWantedLists[mwl]!
        return cards.contains(self.code)
    }
    
    // special for ICE: return primary subtype (Barrier, CG, Sentry, Trap, Mythic) or "Multi"
    var iceType: String? {
        assert(self.type == .ice, "not an ice")
        
        if Card.multiIce.contains(self.code) {
            return "Multi".localized()
        }
        
        return self.subtypes.count == 0 ? "ICE".localized() : self.subtypes[0]
    }
    
    // special for Programs: return "Icebreaker" for icebreakers, "Program" for other programs
    var programType: String? {
        assert(self.type == .program, "not a program")
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
        assert(self.faction != .none)
        return Card.factionColors[self.faction]!
    }
    
    fileprivate var _attributedText: NSAttributedString?
    // html rendered
    var attributedText: NSAttributedString! {
        if self._attributedText == nil {
            let str = self.text.replacingOccurrences(of: "\n", with: "<br/>")
            let data = str.data(using: String.Encoding.utf8)
            self._attributedText = NSAttributedString(htmlData: data, options: Card.coreTextOptions, documentAttributes: nil)
            if self._attributedText == nil {
                self._attributedText = NSAttributedString(string: "")
            }
        }
        return self._attributedText!
    }

    var octgnCode: String {
        return Card.octgnPrefix + self.code
    }
    
    var cropY: Double {
        assert(self.type != .none)
        return Card.cropValues[self.type]!
    }
    
    // how many copies owned
    var owned: Int {
        let prebuiltOwned = PrebuiltManager.quantityFor(self)
        
        if self.isCore {
            let cores = UserDefaults.standard.integer(forKey: SettingsKeys.NUM_CORES)
            return (cores * self.quantity) + prebuiltOwned
        }
        
        let disabledPacks = PackManager.disabledPackCodes()
        if disabledPacks.contains(self.packCode) {
            return prebuiltOwned
        }
        return self.quantity
    }
    
    var isValid: Bool {
        return self.role != .none && self.faction != .none && self.type != .none
    }
    
    var costString: String {
        return xStringify(self.cost)
    }
    
    var strengthString: String {
        return xStringify(self.strength)
    }
    
    fileprivate func xStringify(_ x: Int) -> String {
        switch x {
        case -1: return ""
        case Card.X: return "X"
        default: return "\(x)"
        }
    }
    
    class func cardsFromJson(_ json: JSON, language: String) -> [Card] {
        var cards = [Card]()
        imgSrcTemplate = json["imageUrlTemplate"].stringValue
        currentLanguage = language
        for cardJson in json["data"].arrayValue {
            let card = Card(json: cardJson, language: language)
            cards.append(card)
        }
        return cards
    }
    
    override fileprivate init() {}
    
    fileprivate init(json: JSON, language: String) {
        super.init()
        let c = self
        c.code = json["code"].stringValue
        c.englishName = json["title"].stringValue
        c.name = json.localized("title", language)
        
        c.factionCode = json["faction_code"].stringValue
        c.faction = Codes.factionForCode(c.factionCode)
        
        let roleCode = json["side_code"].stringValue
        c.role = Codes.roleForCode(roleCode)
        
        c.typeCode = json["type_code"].stringValue
        c.type = Codes.typeForCode(c.typeCode)
        
        if c.type == .identity {
            Card.fullNames[c.code] = c.englishName
            let factionName = c.faction == .weyland ? Faction.WeylandConsortium : c.factionStr
            let shortName = Card.shortIdentityName(c.name, forRole: c.role, andFaction: factionName)
            c.name = shortName
        }
        
        c.text = json.localized("text", language)
        c.flavor = json.localized("flavor", language)
        
        c.packCode = json["pack_code"].stringValue
        if c.packCode == "" {
            c.packCode = PackManager.unknownSet
            c.packCode = PackManager.unknownSet
        }
        if c.packCode == PackManager.draftSetCode {
            c.faction = .neutral
        }
        
        c.packNumber = PackManager.packNumberForCode(c.packCode)
        c.isCore = c.packCode == PackManager.coreSetCode
        
        c.subtype = json.localized("keywords", language)
        if c.subtype.length > 0 {
            let split = Card.subtypeSplit(c.subtype)
            c.subtype = split.subtype
            c.subtypes = split.subtypes
        }
        
        c.number = json["position"].int ?? -1
        c.quantity = json["quantity"].int ?? -1
        c.unique = json["uniqueness"].boolValue
        
        if c.type == .identity {
            c.influenceLimit = json["influence_limit"].int ?? -1
            c.minimumDecksize = json["minimum_deck_size"].int ?? -1
            c.baseLink = json["base_link"].int ?? -1
        }
        if c.type == .agenda {
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
        if Card.max1perDeck.contains(c.code) || c.type == .identity {
            c.maxPerDeck = 1
        }
        
        c.isAlliance = c.subtype.lowercased().contains("alliance")
        c.isVirtual = c.subtype.lowercased().contains("virtual")
        if c.type == .ice {
            let barrier = c.subtypes.contains("Barrier")
            let sentry = c.subtypes.contains("Sentry")
            let codeGate = c.subtypes.contains("Code Gate")
            if barrier && sentry && codeGate {
                // print("multi: \(c.name)")
                Card.multiIce.append(c.code)
            }
        }
    }
    
    fileprivate class func subtypeSplit(_ subtype: String) -> (subtype: String, subtypes: [String]) {
        let s = subtype.replacingOccurrences(of: "G-Mod", with: "G-mod")
        let t = s.replacingOccurrences(of: " – ", with: " - ") // fix dashes in german subtypes
        if s != t {
            print("dashes found!")
        }
        var subtypes = t.components(separatedBy: " - ")
        for i in 0 ..< subtypes.count {
            subtypes[i] = subtypes[i].trim()
        }
        return (subtype, subtypes)
    }
    
    func setCardAlias(_ alias: String) {
        self.alias = alias
    }
    
    // manipulate identity name
    class func shortIdentityName(_ name: String, forRole role: NRRole, andFaction faction: String) -> String {
        if let colon = name.range(of: ": ") {
            // runner: remove stuff after the colon ("Andromeda: Disposessed Ristie" becomes "Andromeda")
            if role == .runner {
                return name.substring(to: colon.lowerBound)
            }
        
            // corp: if faction name is part of the title, remove it ("NBN: The World is Yours*" becomes "The World is Yours*")
            // otherwise, remove stuff after the colon ("Harmony Medtech: Biomedical Pioneer" becomes "Harmony Medtech")
            if role == .corp {
                if name.hasPrefix(faction + ": ") {
                    return name.substring(from: name.index(colon.lowerBound, offsetBy: 2)) // bump to after the ": "
                } else {
                    return name.substring(to: colon.lowerBound)
                }
            }
        }
        return name
    }
    
    fileprivate static let factionColors: [NRFaction: UInt] = [
        .jinteki:      0x940c00,
        .nbn:          0xd7a32d,
        .weyland:      0x2d7868,
        .haasBioroid:  0x6b2b8a,
        .shaper:       0x6ab545,
        .criminal:     0x4f67b0,
        .anarch:       0xf47c28,
        .adam:         0xae9543,
        .apex:         0xa8403d,
        .sunnyLebeau:  0x776e6f,
        .neutral:      0x000000
    ]
    
    fileprivate static let cropValues: [NRCardType: Double] = [
        .agenda: 15,
        .asset: 20,
        .event: 10,
        .identity: 12,
        .operation: 10,
        .hardware: 18,
        .ice: 209,
        .program: 8,
        .resource: 11,
        .upgrade: 22
    ]
    
    static let fontFamily = UIFont.systemFont(ofSize: 13).familyName
    static let coreTextOptions = [
        DTUseiOS6Attributes: true,
        DTDefaultFontFamily: NSString(string: fontFamily),
        DTDefaultFontSize: 13
    ] as [String : Any]
    
    override var hashValue: Int {
        return code.hashValue
    }
}

func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.code == rhs.code
}
