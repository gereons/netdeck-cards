//
//  DeckHistorySectionHeaderView.swift
//  Net Deck
//
//  Created by Gereon Steffens on 17.04.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

// NB this is used both on iPad and iPhone

@objc(DeckHistorySectionHeaderView) class DeckHistorySectionHeaderView: UIView {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var revertButton: UIButton!
    
    class func initFromNib() -> DeckHistorySectionHeaderView {
        let views = Bundle.main.loadNibNamed("DeckHistorySectionHeaderView", owner: self, options: nil)
        let header = views?.first as! DeckHistorySectionHeaderView
        return header
    }

}


