//
//  EmptyDetailViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.06.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

class EmptyDetailViewController: UIViewController {
    @IBOutlet weak var emptyDataSetView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = "No Card Data".localized()
        self.textLabel.text = "To use this app, you must first download card data.".localized()
        self.downloadButton.setTitle("Download".localized(), for: .normal)
        
        self.navigationController?.navigationBar.barTintColor = .white
        
        let cardsAvailable = CardManager.cardsAvailable
        self.emptyDataSetView.isHidden = cardsAvailable
        self.spinner.isHidden = !cardsAvailable
        
        if !cardsAvailable {
            self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTileLight)
        }
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.spinner?.stopAnimating()
    }
    
    @IBAction func downloadTapped(_ sender: UIButton) {
        DataDownload.downloadCardData()
    }
}
