//
//  CardDetailView.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

protocol CardDetailDisplay {
    var detailView: UIView! { get }
    var cardName: UILabel! { get }
    var cardType: UILabel! { get }
    var cardText: UITextView! { get }
    
    var label1: UILabel! { get }
    var label2: UILabel! { get }
    var label3: UILabel! { get }
    var icon1: UIImageView! { get }
    var icon2: UIImageView! { get }
    var icon3: UIImageView! { get }
}

class CardDetailView {

    private var card: Card
    private var details: CardDetailDisplay
    
    static func setup(from details: CardDetailDisplay, card: Card) {
        let cdv = CardDetailView(details, card)
        cdv.setup()
    }
    
    init(_ details: CardDetailDisplay, _ card: Card) {
        self.details = details
        self.card = card
    }
    
    private func setup() {
        self.details.detailView.isHidden = false
        self.details.detailView.backgroundColor = UIColor(white: 1, alpha: 0.7)
        self.details.detailView.layer.cornerRadius = 10
        self.details.detailView.layer.masksToBounds = true
        
        if BuildConfig.debug {
            self.details.cardName.text = card.name + " (" + card.code + ")"
        } else {
            self.details.cardName.text = card.name
        }
        
        // hack: remove padding from the text view
        // see https://stackoverflow.com/questions/746670/how-to-lose-margin-padding-in-uitextview
        self.details.cardText.textContainer.lineFragmentPadding = 0
        self.details.cardText.textContainerInset = UIEdgeInsets.zero
        self.details.cardText.attributedText = card.attributedText
        
        let factionName = Faction.name(for: card.faction)
        let typeName = CardType.name(for: card.type)
        let subtype = card.subtype
        if subtype.count > 0 {
            self.details.cardType.text = String(format: "%@ · %@: %@", factionName, typeName, card.subtype)
        } else {
            self.details.cardType.text = String(format: "%@ · %@", factionName, typeName)
        }
            
        // labels from top: cost/strength/mu
        switch card.type {
        case .identity:
            self.details.label1.text = "\(card.minimumDecksize)"
            self.details.icon1.image = ImageCache.cardIcon
            if card.influenceLimit == -1 {
                self.details.label2.text = "∞"
            } else {
                self.details.label2.text = "\(card.influenceLimit)"
            }
            self.details.icon2.image = ImageCache.influenceIcon
            if card.role == .runner {
                self.details.label3.text = "\(card.baseLink)"
                self.details.icon3.image = ImageCache.linkIcon
            } else {
                self.details.label3.text = ""
                self.details.icon3.image = nil
            }
                
        case .program, .resource, .event, .hardware:
            let cost = card.costString
            let str = card.strengthString
            self.details.label1.text = cost // card.cost != -1 ? [NSString stringWithFormat:@"%ld", (long)card.cost] : @""
            self.details.icon1.image = cost.count > 0 ? ImageCache.creditIcon : nil
            self.details.label2.text = str
            self.details.icon2.image = str.count > 0 ? ImageCache.strengthIcon : nil
            self.details.label3.text = card.mu != -1 ? "\(card.mu)" : ""
            self.details.icon3.image = card.mu != -1 ? ImageCache.muIcon : nil
            
        case .ice:
            let cost = card.costString
            let str = card.strengthString
            self.details.label1.text = cost
            self.details.icon1.image = cost.count > 0 ? ImageCache.creditIcon : nil
            self.details.label2.text = ""
            self.details.icon2.image = nil
            self.details.label3.text = str
            self.details.icon3.image = str.count > 0 ? ImageCache.strengthIcon : nil
            
        case .agenda:
            self.details.label1.text = "\(card.advancementCost)"
            self.details.icon1.image = ImageCache.difficultyIcon
            self.details.label2.text = ""
            self.details.icon2.image = nil
            self.details.label3.text = "\(card.agendaPoints)"
            self.details.icon3.image = ImageCache.apIcon
            
        case .asset, .operation, .upgrade:
            let cost = card.costString
            self.details.label1.text = cost
            self.details.icon1.image = cost.count > 0 ? ImageCache.creditIcon : nil
            self.details.label2.text = ""
            self.details.icon2.image = nil
            self.details.label3.text = card.trash != -1 ? "\(card.trash)" : ""
            self.details.icon3.image = card.trash != -1 ? ImageCache.trashIcon : nil
            
        case .none:
            assert(false, "this can't happen")
        }
    }
}
