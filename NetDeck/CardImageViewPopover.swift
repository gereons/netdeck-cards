//
//  CardImageViewPopover.swift
//  Net Deck
//
//  Created by Gereon Steffens on 28.12.13.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class CardImageViewPopover: UIViewController, UIPopoverPresentationControllerDelegate, CardDetailDisplay {
    
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
    
    @IBOutlet weak var mwlLabel: InsetLabel!
    @IBOutlet weak var mwlRightDistance: NSLayoutConstraint!
    @IBOutlet weak var mwlBottomDistance: NSLayoutConstraint!
    
    private var card: Card!
    private var mwl: MWL!
    
    private static var keyboardMonitor: KeyboardMonitor!
    private static var keyboardObserver: KeyboardObserver!
    
    private static var popover: CardImageViewPopover?
    
    private static var keyboardVisible = false
    private static var popoverScale: CGFloat = 1.0
    
    private static let popoverMargin: CGFloat = 40
    
    // MARK: - keyboard monitor
    
    static func monitorKeyboard() {
        keyboardMonitor = KeyboardMonitor()
        keyboardObserver = KeyboardObserver(handler: keyboardMonitor)
    }
    
    static func showKeyboard(_ info: KeyboardInfo) {
        keyboardVisible = true

        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - info.endFrame.origin.y
        popoverScale = (screenHeight - kbHeight - popoverMargin) / CGFloat(ImageCache.height)
        popoverScale = min(1.0, popoverScale)
    }
    
    static func hideKeyboard() {
        keyboardVisible = false
        popoverScale = 1.0
        
        if let p = popover {
            p.view.transform = .identity
            p.preferredContentSize = CGSize(width: ImageCache.width, height: ImageCache.height)
        }
    }
    
    // MARK: - show/dismis
    
    static func show(for card: Card, from rect: CGRect, in vc: UIViewController, subView view: UIView) {
        show(for: card, mwl: nil, from: rect, in: vc, subView: view)
    }
    
    static func show(for card: Card, mwl: MWL?, from rect: CGRect, in vc: UIViewController, subView view: UIView) {
        assert(CardImageViewPopover.popover == nil, "previous popover still visible?")
        
        let popover = CardImageViewPopover()
        popover.card = card
        popover.mwl = mwl ?? Defaults[.defaultMWL]
        
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
        
        let penalty = card.mwlPenalty(self.mwl)
        
        self.mwlLabel.isHidden = penalty == 0
        self.mwlLabel.text = (self.mwl.universalInfluence ? "+" : "-") + "\(penalty)"
        switch card.type {
        case .event, .hardware, .resource, .program, .ice:
            self.mwlRightDistance.constant = 6
            self.mwlBottomDistance.constant = 124
        case .agenda, .asset, .upgrade, .operation:
            self.mwlRightDistance.constant = 154
            self.mwlBottomDistance.constant = 15
        default:
            self.mwlLabel.isHidden = true
        }
        
        self.packLabel.layer.cornerRadius = 3
        self.packLabel.layer.masksToBounds = true
        self.packLabel.text = nil
        
        self.mwlLabel.layer.cornerRadius = 3
        self.mwlLabel.layer.masksToBounds = true
        self.mwlLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 9, weight: UIFont.Weight.bold)
        
        self.activityIndicator.startAnimating()
        self.loadCardImage(self.card)
    }
    
    @objc func imgTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            CardImageViewPopover.dismiss()
        }
    }
    
    private func loadCardImage(_ card: Card) {
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

private class KeyboardMonitor: KeyboardHandling {
    func keyboardWillShow(_ info: KeyboardInfo) {
        CardImageViewPopover.showKeyboard(info)
    }
    
    func keyboardWillHide(_ info: KeyboardInfo) {
        CardImageViewPopover.hideKeyboard()
    }
}
