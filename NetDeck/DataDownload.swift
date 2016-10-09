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
    case all
    case missing
}

private enum ApiRequest {
    case cycles
    case packs
    case cards
    case prebuiltDecks
}

class DataDownload: NSObject {
    
    class func downloadCardData() {
        self.instance.downloadCardAndSetsData()
    }
    
    class func downloadAllImages() {
        self.instance.doDownloadImages(.all)
    }
    
    class func downloadMissingImages() {
        self.instance.doDownloadImages(.missing)
    }
    
    static fileprivate let instance = DataDownload()
    
    fileprivate var sdcAlert: AlertController?
    fileprivate var progressView: UIProgressView?
    fileprivate var downloadStopped = false
    fileprivate var downloadErrors = 0
    
    fileprivate var cards = [Card]()
    
    // MARK: - card and sets download
    
    fileprivate func downloadCardAndSetsData() {
        if let nrdbHost = UserDefaults.standard.string(forKey: SettingsKeys.NRDB_HOST), nrdbHost.length > 0 {
            self.showDownloadAlert()
            self.perform(#selector(DataDownload.doDownloadCardData(_:)), with: nil, afterDelay: 0.01)
        } else {
            UIAlertController.alert(withTitle: nil, message: "No known NetrunnerDB server".localized(), button: "OK".localized());
            return
        }
    }

    fileprivate func showDownloadAlert() {
        let alert = AlertController(title: "Downloading Card Data".localized(), message:nil, preferredStyle: .alert)
        alert.visualStyle = CustomAlertVisualStyle(alertStyle: .alert)
        self.sdcAlert = alert
        
        let act = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        act.startAnimating()
        act.translatesAutoresizingMaskIntoConstraints = false
        alert.contentView.addSubview(act)
        act.centerXAnchor.constraint(equalTo: alert.contentView.centerXAnchor).isActive = true
        act.topAnchor.constraint(equalTo: alert.contentView.topAnchor).isActive = true
        act.bottomAnchor.constraint(equalTo: alert.contentView.bottomAnchor).isActive = true
        
        self.downloadStopped = false
        self.downloadErrors = 0
        
        alert.add(AlertAction(title:"Stop".localized(), style: .normal) { (action) -> Void in
            self.stopDownload()
        })
        
        alert.present(animated: false, completion: nil)
    }
    
    @objc fileprivate func doDownloadCardData(_ dummy: AnyObject) {
        let settings = UserDefaults.standard
        let nrdbHost = settings.string(forKey: SettingsKeys.NRDB_HOST)
        let language = settings.string(forKey: SettingsKeys.LANGUAGE) ?? "en"
        
        let cyclesUrl = String(format: "https://%@/api/2.0/public/cycles?_locale=%@", nrdbHost!, language)
        let packsUrl = String(format: "https://%@/api/2.0/public/packs?_locale=%@", nrdbHost!, language)
        let cardsUrl = String(format: "https://%@/api/2.0/public/cards?_locale=%@", nrdbHost!, language)
        let prebuiltUrl = String(format: "https://%@/api/2.0/public/prebuilts?_locale=%@", nrdbHost!, language)
        
        let requests: [ApiRequest: URLRequest] = [
            .cycles: URLRequest(url:URL(string: cyclesUrl)!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20),
            .packs: URLRequest(url:URL(string: packsUrl)!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20),
            .cards: URLRequest(url:URL(string: cardsUrl)!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20),
            .prebuiltDecks: URLRequest(url:URL(string: prebuiltUrl)!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20)
        ]
        
        let group = DispatchGroup()
        var results = [ApiRequest: JSON]()
        
        for (key, req) in requests {
            group.enter()
            Alamofire.request(req).responseJSON { response in
                switch response.result {
                case .success(let value):
                    if !self.downloadStopped {
                        results[key] = JSON(value)
                    }
                case .failure:
                    break
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            // print("dl finished. stopped=\(self.downloadStopped), \(results.count) results")
            // for a in results.keys {
            //    print("  \(a)")
            // }
            
            var ok = !self.downloadStopped && results.count == requests.count
            if ok {
                ok = PackManager.setupFromNetrunnerDb(results[.cycles]!, results[.packs]!, language: language)
                // print("packs setup ok=\(ok)")
                if ok {
                    ok = CardManager.setupFromNetrunnerDb(results[.cards]!, language: language)
                    // print("cards setup ok=\(ok)")
                }
                if ok {
                    ok = PrebuiltManager.setupFromNetrunnerDb(results[.prebuiltDecks]!, language: language)
                    // print("prebuilt setup ok = \(ok)")
                }
                CardManager.setNextDownloadDate()
            }
            
            if let alert = self.sdcAlert {
                alert.dismiss(animated: false)
                if !ok {
                    let msg = "Unable to download cards at this time. Please try again later.".localized()
                    UIAlertController.alert(withTitle: nil, message: msg, button: "OK")
                }
            }
            self.sdcAlert = nil
            NotificationCenter.default.post(name: Notifications.loadCards, object:self, userInfo:["success": ok])
        }
    }
    
    
    // MARK: - image download
    
    fileprivate func doDownloadImages(_ scope: DownloadScope) {
        self.cards = CardManager.allCards()
        
        if scope == .missing {
            var missing = [Card]()
            for card in self.cards {
                if !ImageCache.sharedInstance.imageAvailable(for: card) {
                    missing.append(card)
                }
            }
            self.cards = missing;
        }
        
        if self.cards.count == 0 {
            if (scope == .all) {
                UIAlertController.alert(withTitle: "No Card Data".localized(),
                    message:"Please download card data first".localized(),
                    button:"OK")
            } else {
                UIAlertController.alert(withTitle: nil,
                    message:"No missing card images".localized(),
                    button:"OK")
            }
            
            return
        }

        let progressView = UIProgressView(progressViewStyle: .default)
        self.progressView = progressView
        progressView.progress = 0
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        let msg = String(format:"Image %d of %d".localized(), 1, self.cards.count)
        let alert = AlertController(title: "Downloading Images".localized(), message:nil, preferredStyle: .alert)
        self.sdcAlert = alert
        
        let attrs = [ NSFontAttributeName: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFontWeightRegular) ]
        alert.attributedMessage = NSAttributedString(string: msg, attributes: attrs)
        
        alert.contentView.addSubview(progressView)
        
        progressView.sdc_pinWidth(toWidthOf: alert.contentView, offset: -20)
        progressView.sdc_centerInSuperview()
        
        alert.add(AlertAction(title: "Stop".localized(), style: .normal) { (action) -> Void in
            self.stopDownload()
        })
        
        alert.present(animated: false, completion: nil)
        
        self.downloadStopped = false
        self.downloadErrors = 0
        
        self.downloadImageForCard(0, scope: scope)
    }
    
    fileprivate func downloadImageForCard(_ index: Int, scope: DownloadScope) {
        if self.downloadStopped {
            return
        }
        
        if index < self.cards.count {
            let card = self.cards[index]
            
            let downloadNext: (Bool) -> Void = { (ok) in
                if !ok {
                    self.downloadErrors += 1
                }
                
                // update the alert
                DispatchQueue.main.async {
                    let progress = Float(index) / Float(self.cards.count)
                    self.progressView?.progress = progress
                    let attrs = [ NSFontAttributeName: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFontWeightRegular) ]
                    let msg = String(format: "Image %d of %d".localized(), index+1, self.cards.count)
                    self.sdcAlert?.attributedMessage = NSAttributedString(string:msg, attributes:attrs)
                }
                
                self.downloadImageForCard(index+1, scope: scope)
            }
            
            if scope == .all {
                ImageCache.sharedInstance.updateImage(for: card, completion: downloadNext)
            } else  {
                ImageCache.sharedInstance.updateMissingImage(for: card, completion: downloadNext)
            }
        } else {
            DispatchQueue.main.async {
                self.sdcAlert?.dismiss(animated:false, completion:nil)
                self.progressView = nil
                self.sdcAlert = nil
                if self.downloadErrors > 0 {
                    let msg = String(format:"%d of %d images could not be downloaded.".localized(),
                                     self.downloadErrors, self.cards.count)
                    
                    UIAlertController.alert(withTitle: nil, message:msg, button:"OK")
                }
                
                self.cards.removeAll()
            }
        }
    }
    
    // MARK: - stop downloads
    
    fileprivate func stopDownload() {
        self.downloadStopped = true
        self.progressView = nil
        self.sdcAlert = nil
    }

    // MARK: - api checker
    
    class func checkNrdbApi(_ url: String, completion: @escaping (Bool) -> Void) {
        Alamofire.request(url)
            .validate()
            .responseJSON { (response) in
                switch response.result {
                case .success:
                    var ok = false
                    if let value = response.result.value {
                        let json = JSON(value)
                        let code = json["data"][0]["code"].stringValue
                        if json.validNrdbResponse && code == "01001" {
                            ok = true
                        }
                    }
                    completion(ok)
                case .failure:
                    completion(false)
                }
        }
    }
}
