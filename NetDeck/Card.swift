//
//  Card.swift
//  NetDeck
//
//  Created by Gereon Steffens on 18.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Marshal

class Card: NSObject, Unmarshaling {
    
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
        executiveSearchFirm, consultingVisit
    ])
    
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
    
    private static let mostWantedLists: [NRMWL: Set<String>] = [
        // MWL v1.0, introduced in Tournament Rules 3.0.2, valid from 2016-02-01 until 2016-07-31
        .v1_0: Set<String>([
            cerberusH1, cloneChip, desperado, parasite, prepaidVoicepad, yog_0,
            architect, astroscript, eli_1, napdContract, sansanCityGrid ]),
        
        // MWL v1.1, introduced in Tournament Regulations v1.1, valid from 2016-08-01 onwards
        .v1_1: Set<String>([
            cerberusH1, cloneChip, d4v1d, desperado, faust, parasite, prepaidVoicepad, wyldside, yog_0,
            architect, breakingNews, eli_1, mumbaTemple, napdContract, sansanCityGrid ])
    ]
    
    private(set) static var fullNames = [String: String]()
    private static let X = -2                   // for strength/cost "X". *MUST* be less than -1!
    
    private(set) var code = ""
    private(set) var name = ""                  // localized name of card, used for display
    private(set) var englishName = ""           // english name of card, used for searches
    private(set) var alias: String?
    private(set) var text = ""
    private(set) var flavor = ""
    private(set) var type = NRCardType.none
    private(set) var subtype = ""               // full subtype string like "Fracter - Icebreaker - AI"
    private(set) var subtypes = [String]()      // array of subtypes like [ "Fracter", "Icebreaker", "AI" ]
    private(set) var faction = NRFaction.none
    private(set) var role = NRRole.none
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
    
    static private var imgSrcTemplate = ""
    static private var currentLanguage = ""
    
    class func null() -> Card {
        return nullInstance
    }
    
    var isNull: Bool {
        return self === Card.nullInstance
    }
    
    func isMostWanted(_ mwl: NRMWL) -> Bool {
        guard let cards = Card.mostWantedLists[mwl] else {
            return false
        }
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
        return UIColor(rgb: self.factionHexColor)
    }
    
    var factionHexColor: UInt {
        assert(self.faction != .none)
        return Card.factionColors[self.faction]!
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
        let prebuiltOwned = PrebuiltManager.quantity(for: self)
        
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
    
    private func xStringify(_ x: Int) -> String {
        switch x {
        case -1: return ""
        case Card.X: return "X"
        default: return "\(x)"
        }
    }
    
    class func cardsFromJson(_ json: JSONObject, language: String) -> [Card] {
        var cards = [Card]()

        imgSrcTemplate = try! json.value(for: "imageUrlTemplate")
        currentLanguage = language
        do {
            cards = try json.value(for: "data")
        } catch {}
        
        return cards
    }
    
    override private init() {}
    
    required init(object: MarshaledObject) throws {
        super.init()
        
        self.code = try object.value(for: "code")
        self.englishName = try object.value(for: "title")
        self.name = try object.localized(for: "title", language: Card.currentLanguage)
        
        self.factionCode = try object.value(for: "faction_code")
        self.faction = Codes.factionFor(code: self.factionCode)
        
        let roleCode: String = try object.value(for: "side_code")
        self.role = Codes.roleFor(code: roleCode)
        
        self.typeCode = try object.value(for: "type_code")
        self.type = Codes.typeFor(code: self.typeCode)
        
        if self.type == .identity {
            Card.fullNames[self.code] = self.englishName
            let factionName = self.faction == .weyland ? Faction.weylandConsortium : self.factionStr
            let shortName = Card.shortIdentityName(self.name, forRole: self.role, andFaction: factionName)
            self.name = shortName
        }
        
        self.text = try object.localized(for: "text", language: Card.currentLanguage)
        
        self.flavor = try object.localized(for: "flavor", language: Card.currentLanguage)
        
        self.packCode = try object.value(for: "pack_code")
        if self.packCode == "" {
            self.packCode = PackManager.unknownSet
        }
        if self.packCode == PackManager.draftSetCode {
            self.faction = .neutral
        }
        
        self.packNumber = PackManager.packNumberFor(code: self.packCode)
        self.isCore = self.packCode == PackManager.coreSetCode
        
        self.subtype = try object.localized(for: "keywords", language: Card.currentLanguage)
        if self.subtype.length > 0 {
            let split = Card.subtypeSplit(self.subtype)
            self.subtype = split.subtype
            self.subtypes = split.subtypes
        }
        
        self.number = try object.value(for: "position") ?? -1
        self.quantity = try object.value(for: "quantity") ?? -1
        self.unique = try object.value(for: "uniqueness")
        
        if self.type == .identity {
            self.influenceLimit = try object.value(for: "influence_limit") ?? -1
            self.minimumDecksize = try object.value(for: "minimum_deck_size") ?? -1
            self.baseLink = try object.value(for: "base_link") ?? -1
        }
        if self.type == .agenda {
            self.advancementCost = try object.value(for: "advancement_cost") ?? -1
            self.agendaPoints = try object.value(for: "agenda_points") ?? -1
        }
        
        self.mu = try object.value(for: "memory_cost") ?? -1
        
        do {
            let str: String? = try object.value(for: "strength")
            if let s = str, s == "X" {
                self.strength = Card.X
            }
        } catch {
            self.strength = try object.value(for: "strength") ?? -1
        }
        
        do {
            let cost: String? = try object.value(for: "cost")
            if let c = cost, c == "X" {
                self.cost = Card.X
            }
        }
        catch {
            self.cost = try object.value(for: "cost") ?? -1
        }
        
        self.influence = try object.value(for: "faction_cost") ?? -1
        self.trash = try object.value(for: "trash_cost") ?? -1
        
        self.maxPerDeck = try object.value(for: "deck_limit") ?? -1
        if Card.max1perDeck.contains(self.code) || self.type == .identity {
            self.maxPerDeck = 1
        }
        
        self.isAlliance = self.subtype.lowercased().contains("alliance")
        self.isVirtual = self.subtype.lowercased().contains("virtual")
        if self.type == .ice {
            let barrier = self.subtypes.contains("Barrier")
            let sentry = self.subtypes.contains("Sentry")
            let codeGate = self.subtypes.contains("Code Gate")
            if barrier && sentry && codeGate {
                // print("multi: \(self.name)")
                Card.multiIce.append(self.code)
            }
        }
    }
    
    private class func subtypeSplit(_ subtype: String) -> (subtype: String, subtypes: [String]) {
        let s = subtype.replacingOccurrences(of: "G-Mod", with: "G-mod")
        let t = s.replacingOccurrences(of: " – ", with: " - ") // fix dashes in german subtypes
        if s != t {
            print("dashes found!")
        }
        var subtypes = t.components(separatedBy: " - ")
        for i in 0 ..< subtypes.count {
            subtypes[i] = subtypes[i].trimmed()
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
    
    private static let factionColors: [NRFaction: UInt] = [
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
    
    private static let cropValues: [NRCardType: Double] = [
        .agenda: 15.0,
        .asset: 20.0,
        .event: 10.0,
        .identity: 12.0,
        .operation: 10.0,
        .hardware: 18.0,
        .ice: 209.0,
        .program: 8.0,
        .resource: 11.0,
        .upgrade: 22.0
    ]
    
    // implement Hashable & Equatable to allow Card objects as dictionary keys
    override var hash: Int {
        return code.hash
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Card {
            return self.code == other.code
        } else {
            return false
        }
    }
}

