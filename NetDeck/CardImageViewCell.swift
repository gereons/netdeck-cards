//
//  CardImageViewCell.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class CardImageViewCell: UICollectionViewCell, CardDetailDisplay {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var packLabel: InsetLabel!
    
    @IBOutlet weak var mwlLabel: InsetLabel!
    @IBOutlet weak var mwlRightDistance: NSLayoutConstraint!
    @IBOutlet weak var mwlBottomDistance: NSLayoutConstraint!
    
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
        self.countLabel.text     = ""
        self.packLabel.text = ""
        self.mwlLabel.text = ""
        
        self.packLabel.layer.cornerRadius = 2
        self.packLabel.layer.masksToBounds = true
        
        self.mwlLabel.layer.cornerRadius = 3
        self.mwlLabel.layer.masksToBounds = true
        self.mwlLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 9, weight: UIFont.Weight.bold)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.detailView.isHidden = true
        self.countLabel.text = ""
        self.packLabel.text = ""
        self.mwlLabel.text = ""
        self.imageView.image = nil
    }
    
    func setCard(_ card: Card, mwl: MWL) {
        self.setCard(card, count: -1, mwl: mwl)
    }
    
    func setCard(_ card: Card, count: Int, mwl: MWL) {
        self.count = card.type == .identity ? 0 : count
        self.card = card
        self.imageView.image = nil
        
        let penalty = card.mwlPenalty(mwl)
        self.mwlLabel.isHidden = penalty == 0
        self.mwlLabel.text = (mwl.universalInfluence ? "+" : "-") + "\(penalty)"
        switch card.type {
        case .event, .hardware, .resource, .program, .ice:
            self.mwlRightDistance.constant = 6
            self.mwlBottomDistance.constant = 124 + self.countLabel.frame.height
        case .agenda, .asset, .upgrade, .operation:
            self.mwlRightDistance.constant = 154
            self.mwlBottomDistance.constant = 15 + self.countLabel.frame.height
        default:
            self.mwlLabel.isHidden = true
        }
        
        self.activityIndicator.startAnimating()
        
        self.loadImage(for:card, count:self.count)
    }
    
    func loadImage(for card: Card, count: Int) {
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placeholder) in
            if self.card.code == card.code {
                self.activityIndicator.stopAnimating()
                self.imageView.image = img
                
                self.packLabel.text = card.packName
                
                
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
