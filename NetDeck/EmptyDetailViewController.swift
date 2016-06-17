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
        self.downloadButton.setTitle("Download".localized(), forState: .Normal)
        
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTileLight)
        
        let cardsAvailable = CardManager.cardsAvailable() && PackManager.packsAvailable()
        self.emptyDataSetView.hidden = cardsAvailable
        self.spinner.hidden = !cardsAvailable
        
        if (cardsAvailable) {
            self.spinner.startAnimating()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let settings = NSUserDefaults.standardUserDefaults()
        if settings.boolForKey(SettingsKeys.UPDATE_2_11) || settings.stringForKey(SettingsKeys.LAST_DOWNLOAD) == "never".localized() {
            return
        }
        
        settings.setBool(true, forKey: SettingsKeys.UPDATE_2_11)
        
        let msg = "Net Deck needs to re-download card data from NetrunnerDB.com".localized()
        let alert = UIAlertController(title: "Welcome to Net Deck v2.11", message: msg, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Not now".localized(), style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Download".localized(), style: .Default) { action in
            DataDownload.downloadCardData()
        })
        self.presentViewController(alert, animated: false, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.spinner.stopAnimating()
    }
    
    @IBAction func downloadTapped(sender: UIButton) {
        DataDownload.downloadCardData()
    }
}