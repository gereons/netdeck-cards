//
//  CardImageViewPopover.swift
//  Net Deck
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class CardImageViewPopover: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
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
    @IBOutlet weak var packLabel: InsetLabel!
    
    private var card: Card!
    
    static var popover: CardImageViewPopover?
    
    static var keyboardVisible = false
    static var popoverScale: CGFloat = 1.0
    
    static let popoverMargin: CGFloat = 40
    
    // MARK: - keyboard monitor
    
    static func monitorKeyboard() {
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector:#selector(self.showKeyboard(_:)), name: Notification.Name.UIKeyboardDidShow, object:nil)
        nc.addObserver(self, selector:#selector(self.hideKeyboard(_:)), name: Notification.Name.UIKeyboardWillHide, object:nil)
    }
    
    static func showKeyboard(_ notification: Notification) {
        keyboardVisible = true
        
        if let kbRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let screenHeight = UIScreen.main.bounds.size.height
            let kbHeight = screenHeight - kbRect.origin.y
            popoverScale = (screenHeight - kbHeight - popoverMargin) / CGFloat(ImageCache.height)
            popoverScale = min(1.0, popoverScale)
        }
    }
    
    static func hideKeyboard(_ notification: Notification) {
        keyboardVisible = false
        popoverScale = 1.0
        
        if let p = popover {
            p.view.transform = .identity
            p.preferredContentSize = CGSize(width: ImageCache.width, height: ImageCache.height)
        }
    }
    
    // MARK: - show/dismis
    
    static func show(for card: Card, from rect: CGRect, in vc: UIViewController, subView view: UIView) {
        assert(CardImageViewPopover.popover == nil, "previous popover still visible?")
        
        let popover = CardImageViewPopover()
        popover.card = card
        
        popover.modalPresentationStyle = .popover
        if let pres = popover.popoverPresentationController {
            pres.sourceRect = rect
            pres.sourceView = view
            pres.permittedArrowDirections = [.left, .right]
            pres.delegate = popover
        }
        popover.preferredContentSize = CGSize(width: Int(ImageCache.width*popoverScale), height: Int(ImageCache.height*popoverScale))
        CardImageViewPopover.popover = popover
        
        vc.present(popover, animated:false, completion:nil)
    }
    
    @discardableResult
    static func dismiss() -> Bool {
        if let p = popover {
            p.dismiss(animated:false, completion:nil)
            popover = nil
            return true
        }
        return false
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        CardImageViewPopover.popover = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.detailView.isHidden = true
        if CardImageViewPopover.keyboardVisible {
            self.view.transform = CGAffineTransform(scaleX: CardImageViewPopover.popoverScale, y: CardImageViewPopover.popoverScale)
        }
        
        self.imageView.isUserInteractionEnabled = true
        let imgTap = UITapGestureRecognizer(target: self, action: #selector(self.imgTap(_:)))
        imgTap.numberOfTapsRequired = 1
        self.imageView.addGestureRecognizer(imgTap)
        
        self.activityIndicator.startAnimating()
        self.loadCardImage(self.card)

    }
    
    func imgTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            CardImageViewPopover.dismiss()
        }
    }
    
    private func loadCardImage() {
        
    }
    
    func loadCardImage(_ card: Card) {
        ImageCache.sharedInstance.getImage(for: card) { (card, img, placeholder) in
            if self.card.code == card.code {
                self.activityIndicator.stopAnimating()
                self.imageView.image = img
                self.packLabel.text = card.packName
                self.packLabel.layer.cornerRadius = 3
                self.packLabel.layer.masksToBounds = true
                
                self.detailView.isHidden = true
                if placeholder {
                    CardDetailView.setup(from: self, card: self.card)
                }
            } else {
                self.loadCardImage(self.card)
            }
        }
    }
}
