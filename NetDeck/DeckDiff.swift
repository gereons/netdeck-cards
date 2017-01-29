//
//  DeckDiff.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

struct CardDiff {
    let card: Card
    let count1: Int
    let count2: Int
}

struct DeckDiff {
    private(set) var fullDiffSections = [String]()
    private(set) var smallDiffSections = [String]()
    private(set) var intersectSections = [String]()
    private(set) var overlapSections = [String]()
    
    private(set) var fullDiffRows = [[CardDiff]]()
    private(set) var smallDiffRows = [[CardDiff]]()
    private(set) var intersectRows = [[CardDiff]]()
    private(set) var overlapRows = [[CardDiff]]()

    init(deck1: Deck, deck2: Deck) {
        let data1 = deck1.dataForTableView(.byType)
        let data2 = deck2.dataForTableView(.byType)
        
        let types1 = data1.sections
        let cards1 = data1.values
        
        let types2 = data2.sections
        let cards2 = data2.values
        
        // get all possible types for this role
        var allTypes = CardType.typesFor(role: deck1.role)
        // overwrite None/Any entry with "Identity"
        allTypes[0] = CardType.name(for: .identity)
        // remove "ICE" / "Program"
        allTypes.removeLast()
        
        let typesInDecks = Set(types1 + types2)
        // find every type that is not already in allTypes - i.e. the ice/program subtypes
        let additionalTypes = typesInDecks.filter { !allTypes.contains($0) }
        
        // sort additionalTypes and append to allTypes
        allTypes.append(contentsOf: additionalTypes.sorted())
        
        let typesUsed = allTypes.filter { typesInDecks.contains($0) }
        self.fullDiffSections = typesUsed
        self.intersectSections = typesUsed
        self.overlapSections = typesUsed
        
        // fill the various ...rows arrays
        for _ in 0 ..< self.fullDiffSections.count {
            self.fullDiffRows.append([CardDiff]())
            self.intersectRows.append([CardDiff]())
            self.overlapRows.append([CardDiff]())
        }
        
        // for each type, find cards in each deck
        for i in 0 ..< self.fullDiffSections.count {
            let type = self.fullDiffSections[i]
            let idx1 = types1.index(of: type)
            let idx2 = types2.index(of: type)
            
            var cards = [String: CardDiff]()
            // create a CardDiff object for each card in deck1
            if let index1 = idx1 {
                for cc in cards1[index1].filter({ !$0.isNull }) {
                    var count2 = 0
                    if let index2 = idx2 {
                        let cc2 = cards2[index2].first { $0.card.code == cc.card.code }
                        count2 = cc2?.count ?? 0
                    }
                    cards[cc.card.code] = CardDiff(card: cc.card, count1: cc.count, count2: count2)
                }
            }
            
            // for each card in deck2 that is not already in `cards´, create a CardDiff object
            if let index2 = idx2 {
                for cc in cards2[index2].filter({ !$0.isNull }) {
                    if cards[cc.card.code] != nil {
                        continue
                    }
                    
                    cards[cc.card.code] = CardDiff(card: cc.card, count1: 0, count2: cc.count)
                }
            }
            
            // sort diffs by card name
            self.fullDiffRows[i] = cards.values.sorted { $0.card.name < $1.card.name }
            
            // fill intersection and overlap - card is in both decks, and the total count is more than we own (for intersect)
            for cd in self.fullDiffRows[i] {
                if cd.count1 > 0 && cd.count2 > 0 {
                    self.overlapRows[i].append(cd)
                    
                    if cd.count1 + cd.count2 > cd.card.owned {
                        self.intersectRows[i].append(cd)
                    }
                }
            }
        }
        
        assert(self.intersectSections.count == self.intersectRows.count, "count mismatch")
        assert(self.overlapSections.count == self.overlapRows.count, "count mismatch")
        
        // remove empty intersecion sections
        for i in (0 ..< self.intersectRows.count).reversed() {
            if self.intersectRows[i].count == 0 {
                self.intersectSections.remove(at: i)
                self.intersectRows.remove(at: i)
            }
        }
        assert(self.intersectSections.count == self.intersectRows.count, "count mismatch")
        
        // remove empty overlap sections
        for i in (0 ..< self.overlapRows.count).reversed() {
            if self.overlapRows[i].count == 0 {
                self.overlapSections.remove(at: i)
                self.overlapRows.remove(at: i)
            }
        }
        assert(self.overlapSections.count == self.overlapRows.count, "count mismatch")
        
        // from the full diff, create the (potentially) smaller diff-only arrays
        for i in 0 ..< self.fullDiffRows.count {
            var arr = [CardDiff]()
            let diff = self.fullDiffRows[i]
            for j in 0 ..< diff.count {
                let cd = diff[j]
                if cd.count1 != cd.count2 {
                    arr.append(cd)
                }
            }
            self.smallDiffRows.append(arr)
        }
        assert(self.smallDiffRows.count == self.fullDiffRows.count, "count mismatch")
        
        for i in (0 ..< self.smallDiffRows.count).reversed() {
            let arr = self.smallDiffRows[i]
            if arr.count > 0 {
                let section = self.fullDiffSections[i]
                self.smallDiffSections.insert(section, at: 0)
            } else {
                self.smallDiffRows.remove(at: i)
            }
        }
        
        assert(self.smallDiffRows.count == self.smallDiffSections.count, "count mismatch")
    }
}
