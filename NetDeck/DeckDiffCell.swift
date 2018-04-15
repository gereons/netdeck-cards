//
//  DeckDiffCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.12.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

class DeckDiffCell: UITableViewCell {

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
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.deck1Card.text = ""
        self.deck2Card.text = ""
        self.diff.text = ""
        
        self.deck1Card.textColor = .black
        self.deck2Card.textColor = .black
        self.diff.textColor = .black
    }
    
    @objc func popupCard1(_ gesture: UITapGestureRecognizer) {
        guard
            let card = self.card1,
            let indexPath = tableView.indexPathForRow(at: gesture.location(in: self.tableView))
        else {
            return
        }
        
        var rect = tableView.rectForRow(at: indexPath)
        rect.size.width = 330
        
        CardImageViewPopover.show(for: card, from: rect, in: self.vc, subView: self.tableView)
    }
    
    @objc func popupCard2(_ gesture: UITapGestureRecognizer) {
        guard
            let card = self.card2,
            let indexPath = tableView.indexPathForRow(at: gesture.location(in: self.tableView))
        else {
            return
        }
        
        var rect = tableView.rectForRow(at: indexPath)
        rect.origin.x = 400
        rect.size.width = 310
        
        CardImageViewPopover.show(for: card, from: rect, in: self.vc, subView: self.tableView)
    }
}
