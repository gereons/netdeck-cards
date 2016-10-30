//
//  CardImageCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class CardImageCell: UICollectionViewCell {

    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var copiesLabel: UILabel!
    
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
    
    private(set) var cc = CardCounter.null()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for img in [self.image1, self.image2, self.image3] {
            img!.layer.masksToBounds = true
            img!.layer.cornerRadius = 10
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for img in [self.image1, self.image2, self.image3] {
            img!.image = nil
        }
        self.detailView.isHidden = true
    }
    
    func loadImage(for cc: CardCounter) {
        self.cc = cc
        self.activityIndicator.startAnimating()
        self.loadImage(card: self.cc.card)
    }
    
    private func loadImage(card: Card) {
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placeholder) in
            if self.cc.card.code == card.code {
                self.activityIndicator.stopAnimating()
                self.setImageStack(img)
                
                self.detailView.isHidden = !placeholder
                if placeholder {
                    CardDetailView.setup(from: self, card: self.cc.card)
                }
            } else {
                self.loadImage(card: self.cc.card)
            }
        }
    }
    
    private func setImageStack(_ image: UIImage) {
        self.image1.image = image
        self.image2.image = self.cc.count > 1 ? image : nil
        self.image3.image = self.cc.count > 2 ? image : nil
        
        let max3: Float = min(Float(self.cc.count), 3.0)
        var c: Float = max(max3-1, 0.0)
        self.image1.layer.opacity = 1.0 - (c * 0.2)
        c = max(c-1, 0.0)
        self.image2.layer.opacity = 1.0 - (c * 0.2)
        c = max(c-1, 0.0)
        self.image3.layer.opacity = 1.0 - (c * 0.2)
    }
    

}
