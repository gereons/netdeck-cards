//
//  BrowserCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.12.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

protocol PopupDisplayer: class {
    func showPopup(for card: Card, in view: UIView, from rect: CGRect)
}

class BrowserCell: UITableViewCell {
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    weak var parent: PopupDisplayer?
    
    var card: Card! {
        didSet {
            self.setCard(card)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    @IBAction func moreClicked(_ sender: UIButton) {
        parent?.showPopup(for: self.card, in: self, from: sender.frame)
    }
    
    func setCard(_ card: Card) {
        fatalError("must be overridden")
    }
}
