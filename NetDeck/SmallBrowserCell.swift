//
//  SmallBrowserCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class SmallBrowserCell: BrowserCell {
    
    @IBOutlet weak var factionLabel: UILabel!
    @IBOutlet weak var pipsView: UIView!
    
    var pips: SmallPipsView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.pips = SmallPipsView.create()
        
        self.pipsView.addSubview(self.pips)
    }
    
    @nonobjc override func setCard(_ card: Card) {
        if card.unique {
            self.nameLabel.text = card.name + " •"
        } else {
            self.nameLabel.text = card.name
        }
        
        let value = card.type == .agenda ? card.agendaPoints : card.influence
        self.pips.set(value: value, color: card.factionColor)
        self.factionLabel.text = card.factionStr
    }
}
