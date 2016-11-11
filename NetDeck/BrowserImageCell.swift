//
//  BrowserImageCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class BrowserImageCell: UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var cardName: UILabel!
    @IBOutlet weak var cardType: UILabel!
    @IBOutlet weak var cardText: UITextView!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var icon1: UIImageView!
    @IBOutlet weak var icon2: UIImageView!
    @IBOutlet weak var icon3: UIImageView!
    
    var card: Card? {
        didSet {
            if card != nil {
                self.activityIndicator.startAnimating()
                self.loadImage(for: card)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        // rounded corners for image
        self.image.layer.masksToBounds = true
        self.image.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    
        self.image.image = nil
        self.card = nil
        self.detailView.isHidden = true
    }
    
    private func loadImage(for card: Card?) {
        guard let card = card, let myCard = self.card else {
            return
        }
        
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placeholder) in
            if myCard.code == card.code {
                self.activityIndicator.stopAnimating()
                self.image.image = img
                
                self.detailView.isHidden = !placeholder
                if placeholder {
                    CardDetailView.setup(from: self, card: card)
                }
            } else {
                self.loadImage(for: self.card)
            }
        }
        
    }

}
