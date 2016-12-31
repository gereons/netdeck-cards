//
//  BrowserCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class BrowserCell: UITableViewCell {
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    var card: Card! {
        didSet {
            self.setCard(card)
        }
    }
    
    @IBAction func moreClicked(_ sender: UIButton) {
        BrowserResultViewController.showPopup(for: self.card, in: self, from: sender.frame)
    }
    
    @nonobjc func setCard(_ card: Card) {
        fatalError("must be overridden")
    }
}
