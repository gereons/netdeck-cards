//
//  EditDeckCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 11.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class EditDeckCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var idButton: UIButton!
    @IBOutlet weak var influenceLabel: UILabel!
    @IBOutlet weak var mwlLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.accessoryView = UIView(frame: CGRect.zero)
        self.influenceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFontWeightRegular)
        self.mwlLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFontWeightRegular)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.influenceLabel.textColor = .black
    }
    
}
