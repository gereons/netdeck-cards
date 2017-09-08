//
//  CardFilterThumbView.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class CardFilterThumbView: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    var card: Card! {
        didSet {
            self.imageView.image = nil
            self.activityIndicator.startAnimating()
            
            self.loadImage(self.card)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.layer.cornerRadius = 8
        self.imageView.layer.masksToBounds = true
        
        self.nameLabel.text = nil
        self.countLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFontWeightRegular)
        self.countLabel.text = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.nameLabel.text = nil
        self.countLabel.text = nil
        self.imageView.image = nil
    }

    private func loadImage(_ card: Card!) {
        guard card != nil else {
            return
        }
        
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placeholder) in
            if self.card.code == card.code {
                self.activityIndicator.stopAnimating()
                self.imageView.image = ImageCache.sharedInstance.croppedImage(img, forCard: card)
                self.nameLabel.text = placeholder ? card.name : nil
            } else {
                self.loadImage(self.card)
            }
        }
    }
}
