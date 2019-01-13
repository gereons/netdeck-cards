//
//  ModalCardImageViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.04.17.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

class ModalCardImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    weak var modalPresenter: ModalViewPresenter!
    var card: Card!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done".localized(), style: .plain, target: self, action: #selector(self.dismiss(_:)))
        
        self.loadImage(for: card)
    }

    @objc func dismiss(_ button: UIBarButtonItem) {
        modalPresenter.dismiss()
    }
    
    func loadImage(for card: Card) {
        ImageCache.sharedInstance.getImage(for: card) { card, image, placeholder in
            self.activityIndicator.stopAnimating()
            self.imageView.image = image
        }
    }
}
