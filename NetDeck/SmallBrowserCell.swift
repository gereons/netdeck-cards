//
//  SmallBrowserCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
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
    
    override func setCard(_ card: Card) {
        let mwl = MWLManager.activeMWL
        self.nameLabel.text = card.displayName(mwl)
        
        let value = card.type == .agenda ? card.agendaPoints : card.influence
        self.pips.set(value: value, color: card.factionColor)
        self.factionLabel.text = card.factionStr
        
        if card.mwlPenalty(mwl) != 0 {
            self.pipsView.backgroundColor = UIColor(rgb: 0xf5f5f5)
        }
    }
}
