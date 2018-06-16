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
        wc2016runner, wc2016corp,
        wc2017runner, wc2017corp,
    ]

    static let wc2015runner = Prebuilt("World Champion 2015 Runner", "wc2015runner", [
        "06073": 3,
        "08083": 3,
        "03054": 3,
        "20035": 3,
        "20017": 3,
        "04089": 3,
        "08087": 3,
        "06059": 1,
        "08022": 3,
        "02103": 3,
        "03053": 3,
        "08062": 3,
        "08108": 3,
        "08043": 1,
        "07030": 1,
        "01018": 2,
        "06033": 2,
        "02042": 3,
        "04102": 2,
        "08061": 3
    ])

    static let wc2015corp = Prebuilt("World Champion 2015 Corp", "wc2015corp", [
        "04015": 3,
        "20116": 1,
        "01055": 3,
        "20068": 3,
        "20075": 3,
        "04114": 2,
        "01054": 1,
        "20064": 3,
        "02092": 3,
        "20063": 1,
        "06061": 3,
        "20129": 2,
        "02110": 3,
        "20071": 2,
        "07027": 1,
        "20132": 3,
        "08033": 3,
        "08040": 3,
        "03017": 2,
        "04119": 3,
        "09026": 2
    ])

    static let wc2016runner = Prebuilt("World Champion 2016 Runner", "wc2016runner", [
        "01012": 3,
        "06073": 2,
        "01014": 2,
        "20009": 2,
        "02001": 1,
        "02009": 1,
        "20013": 2,
        "07043": 1,
        "08062": 3,
        "03053": 3,
        "07032": 3,
        "20056": 3,
        "20016": 1,
        "08047": 1,
        "09053": 2,
        "11041": 2,
        "01002": 1,
        "11026": 3,
        "20003": 1,
        "01010": 2,
        "20015": 1,
        "03052": 3,
        "06120": 1,
        "11024": 2
    ])

    static let wc2016corp = Prebuilt("World Champion 2016 Corp", "wc2016corp", [
        "09013": 2,
        "04015": 3,
        "20116": 2,
        "10092": 2,
        "01082": 3,
        "10074": 1,
        "04076": 3,
        "10053": 3,
        "10076": 2,
        "20119": 2,
        "01092": 2,
        "20128": 1,
        "20115": 2,
        "09015": 3,
        "20129": 1,
        "20132": 3,
        "20120": 1,
        "01081": 1,
        "09018": 2,
        "10054": 2,
        "11017": 1,
        "20110": 3,
        "09026": 3,
        "11016": 2
    ])

    static let wc2017runner = Prebuilt("World Champion 2017 Runner", "wc2017runner", [
        "20005": 1,
        "11085": 1,
        "11030": 1,
        "06079": 2,
        "03037": 1,
        "03048": 1,
        "10079": 1,
        "08025": 1,
        "12008": 1,
        "03035": 1,
        "08001": 1,
        "03046": 2,
        "11109": 3,
        "20056": 3,
        "20049": 1,
        "13022": 3,
        "13027": 1,
        "03040": 1,
        "11104": 2,
        "08085": 3,
        "20029": 1,
        "20039": 3,
        "12088": 1,
        "03053": 3,
        "03034": 1,
        "20054": 3,
        "11070": 1,
        "09035": 1,
        "10009": 1
    ])

    static let wc2017corp = Prebuilt("World Champion 2017 Corp", "wc2017corp", [
        "20068": 1,
        "11117": 2,
        "10095": 2,
        "11060": 1,
        "20072": 3,
        "13038": 3,
        "11049": 3,
        "10037": 1,
        "13057": 2,
        "03001": 1,
        "20132": 3,
        "11031": 1,
        "12072": 2,
        "06061": 2,
        "20129": 1,
        "12111": 3,
        "11111": 3,
        "13030": 2,
        "20063": 3,
        "03026": 1,
        "07027": 1,
        "03005": 3,
        "06066": 3,
        "10067": 3
    ])
}
