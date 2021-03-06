//
//  InfluenceStats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import CorePlot

class InfluenceStats: Stats {
    
    private var colors = [String: UIColor]()
    
    init(deck: Deck) {
        super.init()
        self.useBlues = false
        
        var influence = [String: Int]()
        for cc in deck.cards {
            let inf = deck.influenceFor(cc)
            if inf > 0 {
                let faction = Faction.name(for: cc.card.faction)
                
                influence[faction] = (influence[faction] ?? 0) + inf
                self.colors[faction] = cc.card.factionColor
            }
        }
        
        let sections = influence.keys.sorted { $0 < $1 }
        let values = sections.map { [influence[$0]!] }
        
        assert(sections.count == values.count)
        
        self.tableData = TableData(sections: sections, values: values)
    }
    
    var hostingView: CPTGraphHostingView {
        return self.hostingView(for: self, identifier: "Influence")
    }
    
    override func sliceFill(for pieChart: CPTPieChart, record index: UInt) -> CPTFill? {
        let faction = self.tableData.sections[Int(index)] 
        let color = self.colors[faction]!
        
        return CPTFill(color: CPTColor(cgColor: color.cgColor))
    }
    
    func dataLabel(for plot: CPTPlot, record index: UInt) -> CPTLayer? {
        let faction = self.tableData.sections[Int(index)] 
        let influence = self.tableData.values[Int(index)][0]
        
        let str = String(format: "%@: %d", faction, influence)
        return CPTTextLayer(text: str)
    }
}


