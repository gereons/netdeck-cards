//
//  CardThumbView.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class CardThumbView: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var card = Card.null() {
        didSet {
            self.imageView.image = nil
            self.activityIndicator.startAnimating()
            self.loadImageFor(self.card)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        self.imageView.layer.cornerRadius = 8
        self.imageView.layer.masksToBounds = true
        self.nameLabel.text = nil
    }
    
    func loadImageFor(_ card: Card) {
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placerholder) in
            if self.card.code == card.code {
                self.activityIndicator.stopAnimating()
                self.imageView.image = ImageCache.sharedInstance.croppedImage(img, forCard: card)
                self.nameLabel.text = placerholder ? card.name : nil
            } else {
                self.loadImageFor(self.card)
            }
        }
        
    }

}
