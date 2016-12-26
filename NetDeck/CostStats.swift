//
//  CostStats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import CorePlot

class CostStats: Stats {
    
    init(deck: Deck) {
        super.init()
        
        var costs = [Int: Int]()
        for cc in deck.cards.filter({ $0.card.cost >= 0 }) {
            let cost = cc.card.cost
            costs[cost] = (costs[cost] ?? 0) + cc.count
        }
        
        let sections = costs.keys.sorted { $0 < $1 }
        let values = sections.map { costs[$0]! }
        
        assert(sections.count == values.count)
        
        self.tableData = TableData(sections: sections as NSArray, andValues: values as NSArray)
    }
    
    var hostingView: CPTGraphHostingView {
        return self.hostingView(for: self, identifier: "Cost")
    }
    
    func dataLabel(for plot: CPTPlot, record index: UInt) -> CPTLayer? {
        let cost = self.tableData.sections[Int(index)] as! Int
        let cards = self.tableData.values[Int(index)] as! Int
        
        let str = String(format: "%d %@\n%d %@".localized(), cost, credString(cost), cards, cardsString(cards))
        return CPTTextLayer(text: str)
    }
    
    func cardsString(_ c: Int) -> String {
        return c == 1 ? "Card".localized() : "Cards".localized()
    }
    
    func credString(_ c: Int) -> String {
        return c == 1 ? "Credit".localized() : "Credits".localized()
    }
}

