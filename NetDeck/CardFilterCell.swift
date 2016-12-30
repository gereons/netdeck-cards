//
//  CardFilterCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class CardFilterCell: UITableViewCell {

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var pipsView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!

    var pips: SmallPipsView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        self.pips = SmallPipsView.create()
        self.pipsView.addSubview(self.pips)
    }

}
