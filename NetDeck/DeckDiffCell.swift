//
//  DeckDiffCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

final class DeckDiffCell: UITableViewCell {

    weak var vc: UIViewController!
    weak var tableView: UITableView!
    var card1: Card?
    var card2: Card?

    @IBOutlet weak var deck1Card: UILabel!
    @IBOutlet weak var deck2Card: UILabel!
    @IBOutlet weak var diff: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.popupCard1(_:)))
        self.deck1Card.addGestureRecognizer(tap1)
        self.deck1Card.isUserInteractionEnabled = true
        self.deck1Card.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.popupCard2(_:)))
        self.deck2Card.addGestureRecognizer(tap2)
        self.deck2Card.isUserInteractionEnabled = true
        self.deck2Card.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)

        let longPress1 = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress1(_:)))
        self.deck1Card.addGestureRecognizer(longPress1)

        let longPress2 = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress2(_:)))
        self.deck2Card.addGestureRecognizer(longPress2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.deck1Card.text = ""
        self.deck2Card.text = ""
        self.diff.text = ""
    }
    
    @objc private func popupCard1(_ gesture: UITapGestureRecognizer) {
        popupCard(self.card1, with: gesture, x: 0, width: 330, showText: false)
    }

    @objc private func popupCard2(_ gesture: UITapGestureRecognizer) {
        popupCard(self.card2, with: gesture, x: 400, width: 310, showText: false)
    }

    @objc private func longPress1(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }

        popupCard(self.card1, with: gesture, x: 0, width: 330, showText: true)
    }

    @objc private func longPress2(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }

        popupCard(self.card2, with: gesture, x: 400, width: 310, showText: true)
    }

    private func popupCard(_ card: Card?, with gesture: UITapGestureRecognizer, x: CGFloat, width: CGFloat, showText: Bool) {
        guard
            let card = card,
            let indexPath = tableView.indexPathForRow(at: gesture.location(in: self.tableView))
        else {
            return
        }
        
        var rect = tableView.rectForRow(at: indexPath)
        rect.origin.x = x
        rect.size.width = width
        
        CardImageViewPopover.show(for: card, from: rect, in: self.vc, subView: self.tableView, showText: showText)
    }
}
