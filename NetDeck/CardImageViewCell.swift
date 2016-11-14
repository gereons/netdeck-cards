//
//  CardImageViewCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class CardImageViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var packLabel: InsetLabel!
    
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
    
    var showAsDifferences = false
    private var count = -1
    private var card = Card.null()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.layer.cornerRadius = 8
        self.imageView.layer.masksToBounds = true
        self.detailView.isHidden = true
        self.countLabel.text = ""
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.detailView.isHidden = true
        self.countLabel.text = ""
        self.imageView.image = nil
    }
    
    func setCard(_ card: Card) {
        self.setCard(card, andCount: -1)
    }
    
    func setCard(_ card: Card, andCount count: Int) {
        self.count = card.type == .identity ? 0 : count
        self.card = card
        self.imageView.image = nil
        
        self.activityIndicator.startAnimating()
        
        self.loadImage(for:card, count:self.count)
    }
    
    func loadImage(for card: Card, count: Int) {
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placeholder) in
            if self.card.code == card.code {
                self.activityIndicator.stopAnimating()
                self.imageView.image = img
                
                self.packLabel.text = card.packName
                self.packLabel.layer.cornerRadius = 2
                self.packLabel.layer.masksToBounds = true
                
                if self.showAsDifferences {
                    self.countLabel.text = String(format: "%+ld", self.count)
                } else {
                    if self.count > 0 {
                        self.countLabel.text = String(format: "%ld×", self.count)
                    } else {
                        self.countLabel.text = ""
                    }
                }
                
                self.detailView.isHidden = !placeholder
                if placeholder {
                    CardDetailView.setup(from: self, card: self.card)
                }
            } else {
                self.loadImage(for: self.card, count: self.count)
            }
        }

    }
}
