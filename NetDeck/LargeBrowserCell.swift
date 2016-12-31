//
//  LargeBrowserCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
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
        
        let radius: CGFloat = 4.0
        for pip in pips {
            var frame = pip.frame
            frame.size = CGSize(width: radius, height: radius)
            pip.frame = frame
            pip.layer.cornerRadius = radius
        }
        
        self.nameLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightMedium)
        for lbl in [ self.label1, self.label2, self.label3 ] {
            lbl?.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightRegular)
        }
        
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
        
        self.setInfluence()
        
        switch card.type {
        case .identity:
            self.label1.text = "\(card.minimumDecksize)"
            self.icon1.image = ImageCache.cardIcon
            self.label2.text = card.influenceLimit == -1 ? "∞" : "\(card.influenceLimit)"
            self.icon2.image = ImageCache.influenceIcon
            if card.role == .runner {
                self.label3.text = "\(card.baseLink)"
                self.icon3.image = ImageCache.linkIcon
            }
        case .program, .resource, .event, .hardware:
            let cost = card.costString
            let str = card.strengthString
            self.label1.text = cost
            self.icon1.image = cost.length > 0 ? ImageCache.creditIcon : nil
            self.label2.text = str
            self.icon2.image = str.length > 0 ? ImageCache.strengthIcon : nil
            self.label3.text = card.mu != -1 ? "\(card.mu)" : nil
            self.icon3.image = card.mu != -1 ? ImageCache.muIcon : nil
        case .ice:
            let cost = card.costString
            let str = card.strengthString
            self.label1.text = cost
            self.icon1.image = cost.length > 0 ? ImageCache.creditIcon : nil
            self.label2.text = card.trash != -1 ? "\(card.trash)" : nil
            self.icon2.image = card.trash != -1 ? ImageCache.trashIcon : nil
            self.label3.text = str
            self.icon3.image = str.length > 0 ? ImageCache.strengthIcon : nil
        case .agenda:
            self.label1.text = "\(card.advancementCost)"
            self.icon1.image = ImageCache.difficultyIcon
            self.label3.text = "\(card.agendaPoints)"
            self.icon3.image = ImageCache.apIcon
        case .asset, .operation, .upgrade:
            let cost = card.costString
            self.label1.text = cost
            self.icon1.image = cost.length > 0 ? ImageCache.creditIcon : nil
            self.label3.text = card.trash != -1 ? "\(card.trash)" : nil
            self.icon3.image = card.trash != -1 ? ImageCache.trashIcon : nil
        case .none:
            fatalError("this can't happen")
        }
    }
    
    private func setInfluence() {
        for i in stride(from: 0, to: self.card.influence, by: 1) {
            let pip = self.pips[i]
            pip.layer.backgroundColor = self.card.factionColor.cgColor
            pip.isHidden = false
        }
        
        let mwlVersion = UserDefaults.standard.integer(forKey: SettingsKeys.MWL_VERSION)
        let mwl = NRMWL(rawValue: mwlVersion) ?? .none
        
        let influence = max(0, self.card.influence) // needed for agendas
        if self.card.isMostWanted(mwl) && influence < self.pips.count {
            let pip = self.pips[influence]
            
            pip.layer.backgroundColor = UIColor.white.cgColor
            pip.layer.borderWidth = 1
            pip.layer.borderColor = UIColor.black.cgColor
            pip.isHidden = false
        }
    }
 
}
