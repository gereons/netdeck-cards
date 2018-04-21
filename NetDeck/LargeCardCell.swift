//
//  LargeCardCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

class LargeCardCell: CardCell {
    
    @IBOutlet weak var type: UILabel!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var icon1: UIImageView!
    @IBOutlet weak var icon2: UIImageView!
    @IBOutlet weak var icon3: UIImageView!
    
    @IBOutlet weak var copiesLabel: UILabel!
    
    @IBOutlet weak var pip1: UIView!
    @IBOutlet weak var pip2: UIView!
    @IBOutlet weak var pip3: UIView!
    @IBOutlet weak var pip4: UIView!
    @IBOutlet weak var pip5: UIView!
    @IBOutlet weak var pip6: UIView!
    
    private var pips = [UIView]()
    private var labels = [UILabel]()
    private var icons = [UIImageView]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.pips = [ self.pip1, self.pip2, self.pip3, self.pip4, self.pip5, self.pip6 ]
        self.labels = [ self.label1, self.label2, self.label3 ]
        self.icons = [ self.icon1, self.icon2, self.icon3 ]

        self.pips.forEach { $0.layer.cornerRadius = $0.frame.width / 2 }
        
        let font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFont.Weight.regular)
        self.name.font = font
        self.labels.forEach { $0.font = font }
        
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
        self.influenceLabel.text = ""
        self.copiesLabel.text = ""
        self.copiesLabel.textColor = .black
        self.name.textColor = .black
        self.label2.textColor = .black
        self.type.text = ""
        self.type.isHidden = false
    }
    
    override func setCardCounter(_ cardCounter: CardCounter?) {
        super.setCardCounter(cardCounter)
        guard let cc = cardCounter else {
            return
        }
        
        let card = cc.card
        
        self.name.text = cc.displayName(self.deck.mwl)
        
        if !self.deck.isDraft && (cc.count > card.owned || card.isRotated) {
            self.name.textColor = .red
        }
        if self.deck.legality == .cacheRefresh && card.isCore && cc.count > card.quantity {
            self.name.textColor = .red
        }
        if card.banned(self.deck.mwl) {
            self.name.textColor = .red
        }
        
        let factionName = Faction.name(for: card.faction)
        let typeName = CardType.name(for: card.type)
        
        let subtype = card.subtype
        if subtype.count > 0 {
            self.type.text = String(format: "%@ · %@: %@", factionName, typeName, card.subtype)
        } else {
            self.type.text = String(format: "%@ · %@", factionName, typeName)
        }
        
        let influence = self.deck.influenceFor(cc)
        
        if influence > 0 || card.mwlPenalty(self.deck.mwl) > 0 {
            self.influenceLabel.text = influence > 0 ? "\(influence)" : ""
            self.influenceLabel.textColor = cc.card.factionColor
            
            let universalInf = self.deck.universalInfluenceFor(cc)
            LargeCardCell.setInfluencePips(self.pips, influence: influence, universalInfluence: universalInf, count: cc.count, card: card, mwl: self.deck.mwl)
        }
        
        self.copiesLabel.isHidden = card.type == .identity
        self.copiesStepper.isHidden = card.type == .identity
        self.identityButton.isHidden = card.type != .identity
        
        LargeCardCell.setLabels(for: card, labels: self.labels, icons: self.icons)
        if card.type == .identity && !self.deck.isDraft {
            let limit = self.deck.influenceLimit
            self.label2.text = "\(limit)"
            if limit != card.influenceLimit {
                self.label2.textColor = .red
            }
        }

        self.copiesStepper.maximumValue = Double(self.deck.isDraft ? 100 : cc.card.maxPerDeck)
        self.copiesStepper.value = Double(cc.count)
        self.copiesLabel.text = String(format: "×%lu", cc.count)
    }
    
    static func setLabels(for card: Card, labels: [UILabel], icons: [UIImageView]) {
        assert(labels.count == 3)
        assert(icons.count == 3)
        
        switch card.type {
        case .identity:
            labels[0].text = "\(card.minimumDecksize)"
            icons[0].image = ImageCache.cardIcon
            labels[1].text = card.influenceLimit == -1 ? "∞" : "\(card.influenceLimit)"
            icons[1].image = ImageCache.influenceIcon
            if card.role == .runner {
                labels[2].text = "\(card.baseLink)"
                icons[2].image = ImageCache.linkIcon
            }
        case .program, .resource, .event, .hardware:
            let cost = card.costString
            let str = card.strengthString
            labels[0].text = cost
            icons[0].image = cost.count > 0 ? ImageCache.creditIcon : nil
            labels[1].text = str
            icons[1].image = str.count > 0 ? ImageCache.strengthIcon : nil
            labels[2].text = card.mu != -1 ? "\(card.mu)" : nil
            icons[2].image = card.mu != -1 ? ImageCache.muIcon : nil
        case .ice:
            let cost = card.costString
            let str = card.strengthString
            labels[0].text = cost
            icons[0].image = cost.count > 0 ? ImageCache.creditIcon : nil
            labels[1].text = card.trash != -1 ? "\(card.trash)" : nil
            icons[1].image = card.trash != -1 ? ImageCache.trashIcon : nil
            labels[2].text = str
            icons[2].image = str.count > 0 ? ImageCache.strengthIcon : nil
        case .agenda:
            labels[0].text = "\(card.advancementCost)"
            icons[0].image = ImageCache.difficultyIcon
            labels[2].text = "\(card.agendaPoints)"
            icons[2].image = ImageCache.apIcon
        case .asset, .operation, .upgrade:
            let cost = card.costString
            labels[0].text = cost
            icons[0].image = cost.count > 0 ? ImageCache.creditIcon : nil
            labels[2].text = card.trash != -1 ? "\(card.trash)" : nil
            icons[2].image = card.trash != -1 ? ImageCache.trashIcon : nil
        case .none:
            fatalError("this can't happen")
        }
    }
    
    static func setInfluencePips(_ pips: [UIView], influence: Int, universalInfluence: Int, count: Int, card: Card, mwl: MWL) {
        let uInf = universalInfluence / count
        let inf = max(0, (influence / count) - uInf)
        
        for i in stride(from: 0, to: inf, by: 1) {
            let pip = pips[i]
            pip.layer.backgroundColor = card.factionColor.cgColor
            pip.isHidden = false
        }

        if mwl.universalInfluence {
            let maxPip = min(pips.count, inf + uInf)
            for i in stride(from: inf, to: maxPip, by: 1) {
                circlePip(pips[i])
            }
        } else {
            let inf = max(0, inf)
            let penalty = card.mwlPenalty(mwl)
            if penalty > 0 && inf < pips.count {
                circlePip(pips[inf])
            }
        }
    }
    
    private static func circlePip(_ pip: UIView) {
        pip.layer.backgroundColor = UIColor.white.cgColor
        pip.layer.borderWidth = 1
        pip.layer.borderColor = UIColor.black.cgColor
        pip.isHidden = false
    }
}
