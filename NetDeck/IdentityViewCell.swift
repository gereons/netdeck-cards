//
//  IdentityViewCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

final class IdentityViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deckSizeLabel: UILabel!
    @IBOutlet weak var influenceLimitLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    
    @IBOutlet weak var deckSizeIcon: UIImageView!
    @IBOutlet weak var influenceIcon: UIImageView!
    @IBOutlet weak var linkIcon: UIImageView!
    
    @IBOutlet weak var infoButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        let font = UIFont.monospacedDigitSystemFont(ofSize:12, weight:UIFont.Weight.regular)
        self.deckSizeLabel.font = font
        self.influenceLimitLabel.font = font
        self.linkLabel.font = font

        self.deckSizeIcon.image = ImageCache.deckSizeIcon
        self.influenceIcon.image = ImageCache.deckInfluenceIcon
        self.linkIcon.image = ImageCache.deckLinkIcon
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.infoButton.removeTarget(nil, action: nil, for: .touchUpInside)

        for gesture in self.gestureRecognizers ?? [] {
            if gesture is UILongPressGestureRecognizer {
                self.infoButton.removeGestureRecognizer(gesture)
            }
        }
    }
}
