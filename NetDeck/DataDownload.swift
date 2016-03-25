//
//  DataDownload.swift
//  NetDeck
//
//  Created by Gereon Steffens on 05.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import SDCAlertView
import Alamofire
import SwiftyJSON

private enum DownloadScope: Int {
    case All
    case Missing
}

class DataDownload: NSObject {
    
    class func downloadCardData() {
        self.instance.downloadCardAndSetsData()
    }
    
    class func downloadAllImages() {
        self.instance.doDownloadImages(.All)
    }
    
    class func downloadMissingImages() {
        self.instance.doDownloadImages(.Missing)
    }
    
    static private let instance = DataDownload()
    
    private var alert: AlertController?
    private var downloadStopped = false
    private var downloadErrors = 0
    
    private var localizedCards: JSON?
    private var englishCards: JSON?
    private var localizedSets: JSON?
    
    private var progressView: UIProgressView!
    
    private var cards: [Card]!
    
    // MARK: - card and sets download
    
    private func downloadCardAndSetsData() {
        let nrdbHost = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_HOST)
            
        if nrdbHost?.length > 0 {
            self.showDownloadAlert()
            self.performSelector(#selector(DataDownload.doDownloadCardData(_:)), withObject: nil, afterDelay: 0.0)
        } else {
            UIAlertController.alertWithTitle(nil, message: "No known NetrunnerDB server".localized(), button: "OK".localized());
            return
        }
    }

    private func showDownloadAlert() {
        let alert = AlertController(title: "Downloading Card Data".localized(), message:nil, preferredStyle:.Alert)
        self.alert = alert
        
        let act = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        act.startAnimating()
        act.translatesAutoresizingMaskIntoConstraints = false
        alert.contentView.addSubview(act)
        act.centerXAnchor.constraintEqualToAnchor(alert.contentView.centerXAnchor).active = true
        act.topAnchor.constraintEqualToAnchor(alert.contentView.topAnchor).active = true
        act.bottomAnchor.constraintEqualToAnchor(alert.contentView.bottomAnchor).active = true
        
        self.downloadStopped = false
        self.downloadErrors = 0
        
        alert.addAction(AlertAction(title:"Stop".localized(), style: .Default) { (action) -> Void in
            self.stopDownload()
        })
        
        alert.present(animated: false, completion:nil)
    }
    
    @objc private func doDownloadCardData(dummy: AnyObject) {
        let settings = NSUserDefaults.standardUserDefaults()
        let nrdbHost = settings.stringForKey(SettingsKeys.NRDB_HOST)
        let language = settings.stringForKey(SettingsKeys.LANGUAGE) ?? "en"
        
        let localCardsUrl = String(format: "http://%@/api/cards/?_locale=%@", nrdbHost!, language)
        let englishCardsUrl = String(format: "http://%@/api/cards/?_locale=en", nrdbHost!)
        let setsUrl = String(format: "http://%@/api/sets/?_locale=%@", nrdbHost!, language)
        
        let localCardsRequest = NSMutableURLRequest(URL:NSURL(string: localCardsUrl)!, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: 10)
        let englishCardsRequest = NSMutableURLRequest(URL:NSURL(string: englishCardsUrl)!, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: 10)
        let setsRequest = NSMutableURLRequest(URL:NSURL(string: setsUrl)!, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: 10)
        
        Alamofire.request(localCardsRequest).responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    self.localizedCards = JSON(value)
                }
            case .Failure:
                self.downloadErrors += 1
            }
            
            if self.downloadStopped {
                return
            }
            
            if language == "en" {
                // no need to download again
                self.englishCards = self.localizedCards
                self.downloadSets(setsRequest)
            } else {
                // get english cards
                Alamofire.request(englishCardsRequest).responseJSON { response in
                    switch response.result {
                    case .Success:
                        if let value = response.result.value {
                            self.englishCards = JSON(value)
                        }
                    case .Failure:
                        self.downloadErrors += 1
                    }
                    
                    if self.downloadStopped {
                        return
                    }
                    
                    self.downloadSets(setsRequest)
                }
            }
        }
    }
    
    private func downloadSets(setsRequest: NSURLRequest) {
        // get sets
        Alamofire.request(setsRequest).responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    self.localizedSets = JSON(value)
                }
            case .Failure:
                self.downloadErrors += 1
            }
            
            self.finishDownloads()
        }
    }
    
    private func finishDownloads() {
        let ok = self.localizedCards != nil
            && self.englishCards != nil
            && self.localizedSets != nil
            && self.downloadErrors == 0
        
        if ok {
            CardManager.setupFromJson(self.englishCards!, local: self.localizedCards!, saveToDisk: true)
            CardSets.setupFromNrdbApi(self.localizedSets!)
            CardManager.setNextDownloadDate()
        }
        
        self.localizedCards = nil
        self.englishCards = nil
        self.localizedSets = nil
        
        if let alert = self.alert {
            alert.dismiss(animated:false) {
                if self.downloadStopped {
                    return
                }
                
                if (!ok) {
                    let msg = "Unable to download cards at this time. Please try again later.".localized()
                    UIAlertController.alertWithTitle(nil, message: msg, button: "OK")
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LOAD_CARDS, object:self, userInfo:["success": ok])
                }
            }
        }
        
        self.alert = nil
    }
    
    // MARK: - image download
    
    private func doDownloadImages(scope: DownloadScope) {
        self.cards = CardManager.allCards()
        
        if scope == .Missing {
            var missing = [Card]()
            for card in self.cards {
                if !ImageCache.sharedInstance.imageAvailableFor(card) {
                    missing.append(card)
                }
            }
            self.cards = missing;
        }
        
        if self.cards.count == 0 {
            if (scope == .All) {
                UIAlertController.alertWithTitle("No Card Data".localized(),
                    message:"Please download card data first".localized(),
                    button:"OK")
            } else {
                UIAlertController.alertWithTitle(nil,
                    message:"No missing card images".localized(),
                    button:"OK")
            }
            
            return
        }

        self.progressView = UIProgressView(progressViewStyle: .Default)
        self.progressView.progress = 0
        
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        
        let msg = String(format:"Image %d of %d".localized(), 1, self.cards.count)
        let alert = AlertController(title: "Downloading Images".localized(), message:nil, preferredStyle: .Alert)
        self.alert = alert
        
        let attrs = [ NSFontAttributeName: UIFont.monospacedDigitSystemFontOfSize(12, weight: UIFontWeightRegular) ]
        alert.attributedMessage = NSAttributedString(string: msg, attributes: attrs)
        
        alert.contentView.addSubview(self.progressView)
        
        self.progressView.sdc_pinWidthToWidthOfView(alert.contentView, offset:-20)
        self.progressView.sdc_centerInSuperview()
        
        alert.addAction(AlertAction(title:"Stop".localized(), style:.Default) { (action) -> Void in
            self.stopDownload()
        })
        
        alert.present(animated:false, completion:nil)
        
        self.downloadStopped = false
        self.downloadErrors = 0
        
        self.downloadImageForCard(["index": 0, "scope": scope.rawValue ])
    }
    
    @objc private func downloadImageForCard(dict: [String: Int]) {
        let index = dict["index"]!
        let scope = DownloadScope(rawValue: dict["scope"]!)!
        
        if self.downloadStopped {
            return
        }
        
        if index < self.cards.count {
            let card = self.cards[index]
            
            let downloadNext: (Bool) -> Void = { (ok) in
                if !ok && card.imageSrc != nil {
                    self.downloadErrors += 1
                }
                self.downloadNextImage([ "index": index+1, "scope": scope.rawValue])
            }
            
            if scope == .All {
                ImageCache.sharedInstance.updateImageFor(card, completion: downloadNext)
            }
            else
            {
                ImageCache.sharedInstance.updateMissingImageFor(card, completion: downloadNext)
            }
        }
    }
    
    private func downloadNextImage(dict: [String: Int]) {
        let index = dict["index"]!
        if index < self.cards.count {
            let progress = (Float(index) * 100.0) / Float(self.cards.count)
            // NSLog(@"%@ - progress %.1f", card.name, progress);
            
            self.progressView.progress = progress/100.0;
            
            if let alert = self.alert {
                let attrs = [ NSFontAttributeName: UIFont.monospacedDigitSystemFontOfSize(12, weight: UIFontWeightRegular) ]
                let msg = String(format:"Image %d of %d".localized(), index+1, self.cards.count)
                alert.attributedMessage = NSAttributedString(string:msg, attributes:attrs)
            }
            
            // use -performSelector: so the UI can refresh
            self.performSelector(#selector(DataDownload.downloadImageForCard(_:)), withObject:dict, afterDelay:0.0)
        }
        else
        {
            self.alert?.dismiss(animated:false, completion:nil)
            self.alert = nil
            if self.downloadErrors > 0 {
                let msg = String(format:"%d of %d images could not be downloaded.".localized(),
                    self.downloadErrors, self.cards.count)
                
                UIAlertController.alertWithTitle(nil, message:msg, button:"OK")
            }
            
            self.cards = nil
        }
    }
    
    // MARK: - stop downloads
    
    private func stopDownload() {
        self.downloadStopped = true
        self.alert = nil
    }

    // MARK: - api checker
    
    class func checkNrdbApi(url: String, completion: (Bool) -> Void) {
        Alamofire.request(.GET, url)
            .validate()
            .responseJSON { (response) in
                switch response.result {
                case .Success:
                    var ok = false
                    if let value = response.result.value {
                        let json = JSON(value)
                        if json[0]["code"].string != nil {
                            ok = true
                        }
                    }
                    completion(ok)
                case .Failure:
                    completion(false)
                }
        }
    }
}
