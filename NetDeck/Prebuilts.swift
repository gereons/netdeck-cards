//
//  Prebuilts.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.05.18.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import Foundation

struct Prebuilt {
    let name: String
    let code: String
    let cards: [String: Int]

    init(_ name: String, _ code: String, _ cards: [String: Int]) {
        self.name = name
        self.code = code
        self.cards = cards
    }

    var settingsKey: String {
        return "use_\(self.code)"
    }
    
    static private(set) var ownedPrebuilts = [Prebuilt]()

    static func initialize() {
        ownedPrebuilts = []
        for p in allPrebuilts {
            if UserDefaults.standard.bool(forKey: p.settingsKey) {
                ownedPrebuilts.append(p)
            }
        }
    }

    static func owned(_ card: Card) -> Int {
        for p in ownedPrebuilts {
            if let c = p.cards[card.code] {
                return c
            } else if let code2 = Card.revisedToOriginal[card.code], let c = p.cards[code2] {
                return c
            }
        }
        return 0
    }

    static func identities(for role: Role) -> [Card] {
        var identities = [Card]()
        for p in ownedPrebuilts {
            for code in p.cards.keys {
                if let card = CardManager.cardBy(code), card.type == .identity, card.role == role {
                    identities.append(card)
                }
            }
        }
        return identities
    }
}

// MARK: - World Champion Decks
extension Prebuilt {
    static let allPrebuilts = [
        wc2015runner, wc2015corp,
        wc2016runner, wc2016corp
    ]

    static let wc2015runner = Prebuilt("World Champion 2015 Runner", "wc2015runner", [
        "01018": 2,
        "02042": 3,
        "02063": 3,
        "02103": 3,
        "03053": 3,
        "03054": 3,
        "04089": 3,
        "04102": 2,
        "04106": 3,
        "06033": 2,
        "06059": 1,
        "06073": 3,
        "07030": 1,
        "08022": 3,
        "08043": 1,
        "08061": 3,
        "08062": 3,
        "08083": 3,
        "08087": 3,
        "08108": 3
    ])

    static let wc2015corp = Prebuilt("World Champion 2015 Corp", "wc2015corp", [
        "01054": 1,
        "01055": 3,
        "01056": 3,
        "01058": 2,
        "01062": 3,
        "01090": 1,
        "01110": 3,
        "01111": 2,
        "02013": 3,
        "02051": 1,
        "02092": 3,
        "02110": 3,
        "03017": 2,
        "04015": 3,
        "04114": 2,
        "04119": 3,
        "06061": 3,
        "07027": 1,
        "08033": 3,
        "08040": 3,
        "09026": 2
    ])

    static let wc2016runner = Prebuilt("World Champion 2016 Runner", "wc2016runner", [
        "01002": 1,
        "01008": 2,
        "01010": 2,
        "01011": 2,
        "01012": 3,
        "01014": 2,
        "01015": 1,
        "01050": 3,
        "02001": 1,
        "02009": 1,
        "02022": 1,
        "02101": 1,
        "03052": 3,
        "03053": 3,
        "06073": 2,
        "06120": 1,
        "07032": 3,
        "07043": 1,
        "08047": 1,
        "08062": 3,
        "09053": 2,
        "11024": 2,
        "11026": 3,
        "11041": 2
    ])

    static let wc2016corp = Prebuilt("World Champion 2016 Corp", "wc2016corp", [
        "01081": 1,
        "01082": 3,
        "01084": 2,
        "01085": 1,
        "01090": 2,
        "01092": 2,
        "01109": 1,
        "01110": 3,
        "01111": 1,
        "02056": 2,
        "02115": 3,
        "04015": 3,
        "04076": 3,
        "09013": 2,
        "09015": 3,
        "09018": 2,
        "09026": 3,
        "10053": 3,
        "10054": 2,
        "10074": 1,
        "10076": 2,
        "10092": 2,
        "11016": 2,
        "11017": 1
    ])
}

