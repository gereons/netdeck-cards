//
//  LargeBrowserCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class LargeBrowserCell: BrowserCell {

    @IBOutlet weak var type: UILabel!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var icon1: UIImageView!
    @IBOutlet weak var icon2: UIImageView!
    @IBOutlet weak var icon3: UIImageView!
    
    @IBOutlet weak var pip1: UIView!
    @IBOutlet weak var pip2: UIView!
    @IBOutlet weak var pip3: UIView!
    @IBOutlet weak var pip4: UIView!
    @IBOutlet weak var pip5: UIView!
    
    private var pips = [UIView]()
    private var labels = [UILabel]()
    private var icons = [UIImageView]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.pips = [ self.pip1, self.pip2, self.pip3, self.pip4, self.pip5 ]
        self.labels = [ self.label1, self.label2, self.label3 ]
        self.icons = [ self.icon1, self.icon2, self.icon3 ]
        
        self.pips.forEach { $0.layer.cornerRadius = $0.frame.width / 2 }
        
        self.nameLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightMedium)
        self.labels.forEach { $0.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightRegular) }
        
        self.prepareForReuse()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.pips.forEach {
            $0.layer.borderWidth = 0
            $0.isHidden = true
        }
        self.labels.forEach { $0.text = nil }
        self.icons.forEach { $0.image = nil }
    }
    
    @nonobjc override func setCard(_ card: Card) {
        if card.unique {
            self.nameLabel.text = card.name + " •"
        } else {
            self.nameLabel.text = card.name
        }
        
        let factionName = Faction.name(for: card.faction)
        let typeName = CardType.name(for: card.type)
        let subtype = card.subtype
        if subtype.length > 0 {
            self.type.text = String(format: "%@ · %@: %@", factionName, typeName, subtype)
        } else {
            self.type.text = String(format: "%@ · %@", factionName, typeName)
        }
        
        let mwlVersion = UserDefaults.standard.integer(forKey: SettingsKeys.MWL_VERSION)
        let mwl = MWL(rawValue: mwlVersion) ?? .none
        LargeCardCell.setInfluencePips(self.pips, influence: self.card.influence, card: self.card, mwl: mwl)
        
        LargeCardCell.setLabels(for: card, labels: self.labels, icons: self.icons)
    }
    
}
