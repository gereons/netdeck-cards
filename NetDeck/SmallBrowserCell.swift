//
//  SmallBrowserCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SmallBrowserCell: BrowserCell {
    
    @IBOutlet weak var factionLabel: UILabel!
    @IBOutlet weak var pipsView: UIView!
    
    var pips: SmallPipsView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.pips = SmallPipsView.create()
        
        self.pipsView.layer.cornerRadius = 2
        self.pipsView.layer.masksToBounds = true
        
        self.pipsView.addSubview(self.pips)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.pipsView.backgroundColor = .white
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
        
        let mwl = Defaults[.defaultMwl]
        if card.mwlPenalty(mwl) != 0 {
            self.pipsView.backgroundColor = UIColor(rgb: 0xf5f5f5)
        }
    }
}
