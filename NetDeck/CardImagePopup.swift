//
//  CardImagePopup.swift
//  NetDeck
//
//  Created by Gereon Steffens on 01.01.17.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

class CardImagePopup: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var copiesLabel: UILabel!
    @IBOutlet weak var copiesStepper: UIStepper!

    private var cc: CardCounter!
    private var deck: Deck!

    static func showFor(cc: CardCounter, inDeck deck: Deck, from rect: CGRect, inViewController vc: UIViewController, subView: UIView, direction: UIPopoverArrowDirection) {
        let popup = CardImagePopup(cc: cc, deck: deck)
        
        popup.modalPresentationStyle = .popover
        popup.popoverPresentationController?.sourceRect = rect
        popup.popoverPresentationController?.sourceView = subView
        popup.popoverPresentationController?.permittedArrowDirections = direction
        
        popup.preferredContentSize = popup.view.frame.size
        
        vc.present(popup, animated: false, completion: nil)
    }
    
    required init(cc: CardCounter, deck: Deck) {
        super.init(nibName: nil, bundle: nil)
        assert(cc.card.type != .identity)
        self.cc = cc
        self.deck = deck
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.copiesStepper.maximumValue = Double(self.deck.isDraft ? 100 : self.cc.card.maxPerDeck)
        self.copiesStepper.value = Double(self.cc.count)
        
        self.copiesLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.semibold)
        self.copiesLabel.text = String(format: "×%lu", self.cc.count)
        self.nameLabel.text = self.cc.card.name
    }
    
    @IBAction func copiesChanged(_ stepper: UIStepper) {
        let count = Int(stepper.value)
        let diff = count - self.cc.count
        self.deck.addCard(self.cc.card, copies: diff)
        self.cc.count = count
        
        self.copiesLabel.text = String(format: "×%lu", count)
        self.copiesLabel.textColor = .black
        if !self.deck.isDraft && count > self.cc.card.owned {
            self.copiesLabel.textColor = .red
        }
        
        NotificationCenter.default.post(name: Notifications.deckChanged, object: self)
        
        if count == 0 {
            self.dismiss(animated: false, completion: nil)
        }
    }
}
