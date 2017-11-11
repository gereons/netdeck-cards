//
//  CardCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

protocol IdentitySelector: class {
    func selectIdentity(_ sender: Any)
}

class CardCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var influenceLabel: UILabel!
    @IBOutlet weak var copiesStepper: UIStepper!
    @IBOutlet weak var identityButton: UIButton!
    
    weak var delegate: IdentitySelector!
    var deck: Deck!
    var cardCounter: CardCounter? {
        didSet {
            self.setCardCounter(self.cardCounter)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.identityButton.setTitle("Switch Identity", for: .normal)
        self.prepareForReuse()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.name.text = nil
        self.influenceLabel.text = nil
    }

    @IBAction func selectIdentity(_ sender: Any) {
        self.delegate.selectIdentity(sender)
    }

    @IBAction func copiesChanged(_ stepper: UIStepper) {
        guard let cc = self.cardCounter else { return }
        let count = Int(stepper.value)
        let diff = count - cc.count
        self.deck.addCard(cc.card, copies: diff)
        
        NotificationCenter.default.post(name: Notifications.deckChanged, object: self)
    }
    
    func setCardCounter(_ cc: CardCounter?) {
        let title = cc == nil ? "Choose Identity" : "Switch Identity"
        self.identityButton.setTitle(title.localized(), for: .normal)
        
        if cc == nil {
            self.identityButton.isHidden = false
            self.copiesStepper.isHidden = true
        }
    }
}
