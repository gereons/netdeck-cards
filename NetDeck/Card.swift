//
//  Card.swift
//  NetDeck
//
//  Created by Gereon Steffens on 18.11.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import SwiftyUserDefaults

final class Card: NSObject {
    private(set) static var fullNames = [String: String]() // code => full names of identities
    
    @objc private(set) var code = ""
    @objc private(set) var name = ""            // localized name of card, used for display
    private(set) var foldedName = ""            // lowercased, no diacritics, for sorting (e.g. "Déjà vu" -> "deja vu")

    @objc private(set) var aliases = [String]()
    @objc private(set) var text = ""
    @objc private(set) var strippedText = ""
    private(set) var flavor = ""
    @objc private(set) var type = CardType.none
    private(set) var subtype = ""                // full subtype string like "Fracter - Icebreaker - AI"
    @objc private(set) var subtypes = [String]() // array of subtypes like [ "Fracter", "Icebreaker", "AI" ]
    @objc private(set) var faction = Faction.none
    private(set) var role = Role.none
    private(set) var influenceLimit = -1        // for id
    private(set) var minimumDecksize = -1       // for id
    private(set) var baseLink = -1              // for runner id
    @objc private(set) var influence = -1
    @objc private(set) var mu = -1
    @objc private(set) var strength = -1
    @objc private(set) var cost = -1
    @objc private(set) var advancementCost = -1  // agenda
    @objc private(set) var agendaPoints = -1     // agenda
    @objc private(set) var trash = -1
    private(set) var number = -1                // card no. in set
    
    @objc private(set) var unique = false
    @objc private(set) var maxPerDeck = -1      // how many may be in deck? currently either 1, 3 or 6

    private(set) var isAlliance = false
    private(set) var isCore = false             // card is from core set
    
    private static var multiIce = [String]()
    
    private static let nullInstance = Card()
    
    private var factionCode = ""
    private var typeCode = ""

    @objc private(set) var packCode = ""
    private(set) var quantity = -1             // number of cards in set
    
    private let subtypeDelimiter = " - "
    private var imageUrl: String?
    
    @objc lazy var typeStr = Translation.forTerm(self.typeCode)

    @objc lazy var factionStr = Translation.forTerm(self.factionCode)
    
    @objc var packName: String {
        return PackManager.packsByCode[self.packCode]?.name ?? ""
    }

    lazy var packNumber = PackManager.packNumberFor(code: self.packCode)

    var imageSrc: String? {
        if let src = self.imageUrl {
            return src
        }

        let src = Card.imgSrcTemplate.replacingOccurrences(of: "{code}", with: self.code)
        return src
    }
    
    var nrdbLink: String {
        return "https://netrunnerdb.com/en/card/" + self.code
    }
    
    static private var imgSrcTemplate = ""
    
    static func null() -> Card {
        return nullInstance
    }
    
    var isNull: Bool {
        return self === Card.nullInstance
    }

    // special for ICE: return primary subtype (Barrier, CG, Sentry, Trap, Mythic) or "Multi"
    var iceType: String {
        assert(self.type == .ice, "not an ice")
        
        if Card.multiIce.contains(self.code) {
            return "Multi".localized()
        }
        
        return self.subtypes.count == 0 ? "ICE".localized() : self.subtypes[0]
    }
    
    // special for Programs: return "Icebreaker" for icebreakers, "Program" for other programs
    var programType: String {
        assert(self.type == .program, "not a program")
        
        if self.subtypes.count > 0 && (self.strength >= 0 || self.strength == NetrunnerDbCard.X) {
            return self.subtypes[0]
        } else {
            return self.typeStr
        }
    }

    var factionColor: UIColor {
        return Faction.color(for: self.faction)
    }
    
    static let octgnPrefix = "bc0f047c-01b1-427f-a439-d451eda"
    var octgnCode: String {
        return Card.octgnPrefix + self.code
    }
    
    // how many copies owned
    var owned: Int {
        let prebuiltOwned = Prebuilt.owned(self)

        if self.packCode == PackManager.core {
            let cores = Defaults[.numOriginalCore]
            return (cores * self.quantity) + prebuiltOwned
        }
        if self.packCode == PackManager.core2 {
            let cores = Defaults[.numRevisedCore]
            return (cores * self.quantity) + prebuiltOwned
        }
        if self.packCode == PackManager.sc19 {
            let cores = Defaults[.numSC19]
            return (cores * self.quantity) + prebuiltOwned
        }

        let disabledPacks = PackManager.disabledPackCodes()
        if disabledPacks.contains(self.packCode) {
            return prebuiltOwned
        }

        return self.quantity + prebuiltOwned
    }
    
    var isRotated: Bool {
        let active = Defaults[.rotationActive]
        return active && PackManager.packsByCode[self.packCode]?.rotated ?? false
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
        case NetrunnerDbCard.X: return "X"
        default: return "\(x)"
        }
    }
 
    private override init() {
        super.init()
    }
   
    func addCardAlias(_ alias: String) {
        if !aliases.contains(alias) {
            self.aliases.append(alias)
        }
    }
    
    // manipulate identity name
    static func shortIdentityName(_ name: String, forRole role: Role, andFaction faction: String) -> String {
        if let colon = name.range(of: ": ") {
            // runner: remove stuff after the colon ("Andromeda: Disposessed Ristie" becomes "Andromeda")
            if role == .runner {
                return String(name[..<colon.lowerBound])
            }
        
            // corp: if faction name is part of the title, remove it ("NBN: The World is Yours*" becomes "The World is Yours*")
            // otherwise, remove stuff after the colon ("Harmony Medtech: Biomedical Pioneer" becomes "Harmony Medtech")
            if role == .corp {
                if name.hasPrefix(faction + ": ") {
                    // bump to after the ": "
                    let index = name.index(colon.lowerBound, offsetBy: 2)
                    return String(name[index...])
                } else {
                    return String(name[..<colon.lowerBound])
                }
            }
        }
        
        return name
    }
}

// MARK: - JSON initialization

extension Card {
    
    convenience init(fromApi card: NetrunnerDbCard) {
        self.init()
        
        self.code = card.code
        self.name = card.title
        self.foldedName = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale.current)
        
        self.factionCode = card.faction_code
        self.faction = Codes.factionFor(code: self.factionCode)
        
        self.role = Codes.roleFor(code: card.side_code)
        
        self.typeCode = card.type_code
        self.type = Codes.typeFor(code: self.typeCode)
        
        if self.type == .identity {
            Card.fullNames[self.code] = self.name
            let factionName = self.faction == .weyland ? Faction.weylandConsortium : self.factionStr
            let shortName = Card.shortIdentityName(self.name, forRole: self.role, andFaction: factionName)
            self.name = shortName
        }
        
        self.text = card.text ?? ""
        self.strippedText = card.stripped_text ?? self.text
        
        self.flavor = card.flavor ?? ""
        
        self.packCode = card.pack_code
        if self.packCode == "" {
            self.packCode = PackManager.unknown
        }
        if self.packCode == PackManager.draft {
            self.faction = .neutral
        }
        
        self.isCore = PackManager.cores.contains(self.packCode)
        
        let keywords = card.keywords ?? ""
        if keywords.count > 0 {
            self.subtype = keywords
            self.subtypes = keywords.components(separatedBy: self.subtypeDelimiter)
        }
        
        self.number = card.position
        self.quantity = card.quantity
        self.unique = card.uniqueness
        
        if self.type == .identity {
            self.influenceLimit = card.influence_limit ?? -1
            self.minimumDecksize = card.minimum_deck_size ?? -1
            self.baseLink = card.base_link ?? -1
        }
        if self.type == .agenda {
            self.advancementCost = card.advancement_cost ?? -1
            self.agendaPoints = card.agenda_points ?? -1
        }
        
        self.mu = card.memory_cost ?? -1
        
        self.cost = card.cost
        self.strength = card.strength
        
        self.influence = card.faction_cost ?? -1
        self.trash = card.trash_cost ?? -1
        
        self.maxPerDeck = card.deck_limit
        
        self.isAlliance = keywords.lowercased().contains("alliance")
        
        if self.type == .ice {
            let kw = keywords.lowercased()
            let barrier = kw.contains("barrier")
            let sentry = kw.contains("sentry")
            let codeGate = kw.contains("code gate")
            if barrier && sentry && codeGate {
                // print("multi: \(self.name)")
                Card.multiIce.append(self.code)
            }
        }
        
        self.imageUrl = card.image_url
    }

    static func cardsFromJson(_ rawCards: ApiResponse<NetrunnerDbCard>) -> [Card] {
        Card.imgSrcTemplate = rawCards.imageUrlTemplate ?? ""
        
        let cards = rawCards.data.map {
            Card(fromApi: $0)
        }
        
        return cards
    }
    
}

