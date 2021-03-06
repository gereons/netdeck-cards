//
//  IdentityCardView.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

class IdentityCardView: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var selectButton: UIButton!

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
        self.selectButton.setTitle("Select".localized(), for: .normal)
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

