//
//  SmallCardCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class SmallCardCell: CardCell {
    
    @IBOutlet weak var factionLabel: UILabel!
    @IBOutlet weak var mwlMarker: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.name.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightRegular)
        
        let diameter: CGFloat = 8
        let frame = CGRect(origin: self.mwlMarker.frame.origin, size: CGSize(width: diameter, height: diameter))
        self.mwlMarker.frame = frame
        self.mwlMarker.layer.cornerRadius = diameter / 2.0
        self.mwlMarker.layer.backgroundColor = UIColor.white.cgColor
        self.mwlMarker.layer.borderColor = UIColor.black.cgColor
        self.mwlMarker.layer.borderWidth = 1
        
        self.prepareForReuse()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.mwlMarker.isHidden = true
        self.factionLabel.text = ""
    }
    
    
    @nonobjc override func setCardCounter(_ cardCounter: CardCounter?) {
        super.setCardCounter(cardCounter)
        
        guard let cc = cardCounter else {
            return
        }
        
        let card = cc.card
        
        self.copiesStepper.isHidden = card.type == .identity
        self.identityButton.isHidden = card.type != .identity
        self.factionLabel.isHidden = card.type == .identity

        self.copiesStepper.maximumValue = Double(self.deck.isDraft ? 100 : cc.card.maxPerDeck)
        self.copiesStepper.value = Double(cc.count)
        
        if card.type == .identity {
            self.name.text = card.name
        } else if card.unique {
            self.name.text = String(format: "%lu× %@ •", cc.count, card.name)
        } else {
            self.name.text = String(format: "%lu× %@", cc.count, card.name)
        }
        
        self.name.textColor = .black
        if !self.deck.isDraft && cc.count > card.owned {
            self.name.textColor = .red
        }
        
        let influence: Int
        if card.type == .agenda {
            influence = card.agendaPoints * cc.count
        } else {
            if self.deck != nil {
                influence = self.deck.influenceFor(cc)
            } else {
                influence = card.influence * cc.count
            }
        }
        
        if influence > 0 {
            self.influenceLabel.textColor = card.factionColor
            self.influenceLabel.text = "\(influence)"
        } else {
            self.influenceLabel.text = ""
        }
        
        let mwl = card.isMostWanted(self.deck.mwl)
        self.mwlMarker.isHidden = !mwl
        
        self.factionLabel.text = card.factionStr
    }
}
