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
    
    private var card = Card.null() 
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        // rounded corners for image
        self.image.layer.masksToBounds = true
        self.image.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    
        self.image.image = nil
        self.card = Card.null()
        self.detailView.isHidden = true
    }
    
    func loadImage(for card: Card) {
        self.card = card
        self.activityIndicator.startAnimating()
        self.doLoadImage(for: card)
    }
    
    private func doLoadImage(for card: Card) {
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placeholder) in
            if self.card.code == card.code {
                self.activityIndicator.stopAnimating()
                self.image.image = img
                
                self.detailView.isHidden = !placeholder
                if placeholder {
                    CardDetailView.setup(from: self, card: card)
                }
            } else {
                self.doLoadImage(for: self.card)
            }
        }
        
    }

}
