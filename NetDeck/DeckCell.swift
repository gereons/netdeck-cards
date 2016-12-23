//
//  DeckCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 01.11.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class DeckCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var identityLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel?   // ipad only
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton?    // ipad only
    @IBOutlet weak var nrdbIcon: UIImageView?   // ipad only

}
