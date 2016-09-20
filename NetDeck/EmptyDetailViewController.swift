//
//  EmptyDetailViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.06.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

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
        self.downloadButton.setTitle("Download".localized(), for: UIControlState())
        
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTileLight)
        
        let cardsAvailable = CardManager.cardsAvailable && PackManager.packsAvailable
        self.emptyDataSetView.isHidden = cardsAvailable
        self.spinner.isHidden = !cardsAvailable
        
        if (cardsAvailable) {
            self.spinner.startAnimating()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.spinner.stopAnimating()
    }
    
    @IBAction func downloadTapped(_ sender: UIButton) {
        DataDownload.downloadCardData()
    }
}
