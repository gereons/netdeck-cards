//
//  CardDetailView.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class CardDetailView {

    var detailView: UIView!
    var cardName: UILabel!
    var cardType: UILabel!
    var cardText: UITextView!
    
    var label1: UILabel!
    var label2: UILabel!
    var label3: UILabel!
    var icon1: UIImageView!
    var icon2: UIImageView!
    var icon3: UIImageView!
    
    var card = Card.null()
    
    static func setup(from: CardImageViewPopover, card: Card) {
        let cdv = CardDetailView()
        
        cdv.icon1 = from.icon1
        cdv.icon2 = from.icon2
        cdv.icon3 = from.icon3
        cdv.label1 = from.label1
        cdv.label2 = from.label2
        cdv.label3 = from.label3
        cdv.detailView = from.detailView
        cdv.cardName = from.cardName
        cdv.cardType = from.cardType
        cdv.cardText = from.cardText
        cdv.card = card
        
        cdv.setup()
    }
    
    static func setup(from: CardImageCell, card: Card) {
        let cdv = CardDetailView()
        
        cdv.icon1 = from.icon1
        cdv.icon2 = from.icon2
        cdv.icon3 = from.icon3
        cdv.label1 = from.label1
        cdv.label2 = from.label2
        cdv.label3 = from.label3
        cdv.detailView = from.detailView
        cdv.cardName = from.cardName
        cdv.cardType = from.cardType
        cdv.cardText = from.cardText
        cdv.card = card
        
        cdv.setup()
    }
    
    static func setup(from: BrowserImageCell, card: Card) {
        let cdv = CardDetailView()
        
        cdv.icon1 = from.icon1
        cdv.icon2 = from.icon2
        cdv.icon3 = from.icon3
        cdv.label1 = from.label1
        cdv.label2 = from.label2
        cdv.label3 = from.label3
        cdv.detailView = from.detailView
        cdv.cardName = from.cardName
        cdv.cardType = from.cardType
        cdv.cardText = from.cardText
        cdv.card = card
        
        cdv.setup()
    }
    
    static func setup(from: CardImageViewCell, card: Card) {
        let cdv = CardDetailView()
        
        cdv.icon1 = from.icon1
        cdv.icon2 = from.icon2
        cdv.icon3 = from.icon3
        cdv.label1 = from.label1
        cdv.label2 = from.label2
        cdv.label3 = from.label3
        cdv.detailView = from.detailView
        cdv.cardName = from.cardName
        cdv.cardType = from.cardType
        cdv.cardText = from.cardText
        cdv.card = card
        
        cdv.setup()
    }

    func setup() {
        self.detailView.isHidden = false
        self.detailView.backgroundColor = UIColor(white: 1, alpha: 0.7)
        self.detailView.layer.cornerRadius = 10
        self.detailView.layer.masksToBounds = true
        
        
        if BuildConfig.debug {
            self.cardName.text = card.name + " (" + card.code + ")"
        } else {
            self.cardName.text = card.name
        }
        
        // hack: remove padding from the text view
        // see https://stackoverflow.com/questions/746670/how-to-lose-margin-padding-in-uitextview
        self.cardText.textContainer.lineFragmentPadding = 0
        self.cardText.textContainerInset = UIEdgeInsets.zero
        self.cardText.attributedText = card.attributedText
        
        let factionName = Faction.name(for: card.faction)
        let typeName = CardType.name(for: card.type)
        let subtype = card.subtype
        if subtype.length > 0 {
            self.cardType.text = String(format: "%@ · %@: %@", factionName, typeName, card.subtype)
        } else {
            self.cardType.text = String(format: "%@ · %@", factionName, typeName)
        }
            
        // labels from top: cost/strength/mu
        switch card.type {
        case .identity:
            self.label1.text = "\(card.minimumDecksize)"
            self.icon1.image = ImageCache.cardIcon
            if card.influenceLimit == -1 {
                self.label2.text = "∞"
            } else {
                self.label2.text = "\(card.influenceLimit)"
            }
            self.icon2.image = ImageCache.influenceIcon
            if card.role == .runner {
                self.label3.text = "\(card.baseLink)"
                self.icon3.image = ImageCache.linkIcon
            } else {
                self.label3.text = ""
                self.icon3.image = nil
            }
                
        case .program, .resource, .event, .hardware:
            let cost = card.costString
            let str = card.strengthString
            self.label1.text = cost // card.cost != -1 ? [NSString stringWithFormat:@"%ld", (long)card.cost] : @""
            self.icon1.image = cost.length > 0 ? ImageCache.creditIcon : nil
            self.label2.text = str
            self.icon2.image = str.length > 0 ? ImageCache.strengthIcon : nil
            self.label3.text = card.mu != -1 ? "\(card.mu)" : ""
            self.icon3.image = card.mu != -1 ? ImageCache.muIcon : nil
            
        case .ice:
            let cost = card.costString
            let str = card.strengthString
            self.label1.text = cost
            self.icon1.image = cost.length > 0 ? ImageCache.creditIcon : nil
            self.label2.text = ""
            self.icon2.image = nil
            self.label3.text = str
            self.icon3.image = str.length > 0 ? ImageCache.strengthIcon : nil
            
        case .agenda:
            self.label1.text = "\(card.advancementCost)"
            self.icon1.image = ImageCache.difficultyIcon
            self.label2.text = ""
            self.icon2.image = nil
            self.label3.text = "\(card.agendaPoints)"
            self.icon3.image = ImageCache.apIcon
            
        case .asset, .operation, .upgrade:
            let cost = card.costString
            self.label1.text = cost
            self.icon1.image = cost.length > 0 ? ImageCache.creditIcon : nil
            self.label2.text = ""
            self.icon2.image = nil
            self.label3.text = card.trash != -1 ? "\(card.trash)" : ""
            self.icon3.image = card.trash != -1 ? ImageCache.trashIcon : nil
            
        case .none:
            assert(false, "this can't happen")
        }
    }
}
