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

private enum DownloadScope {
    case All
    case Missing
}

class DataDownload: NSObject {
    
    class func downloadCardData() {
        FIXME("get rid of the singleton")
        self.instance.downloadCardAndSetsData()
    }
    
    class func downloadAllImages() {
        
    }
    
    class func downloadMissingImages() {
        
    }
    
    private static let instance = DataDownload()
    
    private var alert: AlertController!
    private var downloadStopped = false
    private var downloadErrors = 0
    
    private var localizedCards: JSON?
    private var englishCards: JSON?
    private var localizedSets: JSON?
    
    private func downloadCardAndSetsData() {
        let nrdbHost = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_HOST)
            
        if nrdbHost?.length > 0 {
            self.showDownloadAlert()
            self.performSelector("doDownloadCardData:", withObject: nil, afterDelay: 0.01)
        } else {
            UIAlertController.alertWithTitle(nil, message: "No known NetrunnerDB server".localized(), button: "OK".localized());
            return
        }
    }

    private func showDownloadAlert() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        self.alert = AlertController(title: "Downloading Card Data".localized(), message:nil, preferredStyle:.Alert)
        
        let act = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        act.startAnimating()
        act.translatesAutoresizingMaskIntoConstraints = false
        self.alert.contentView.addSubview(act)
        act.centerXAnchor.constraintEqualToAnchor(self.alert.contentView.centerXAnchor).active = true
        act.topAnchor.constraintEqualToAnchor(self.alert.contentView.topAnchor).active = true
        act.bottomAnchor.constraintEqualToAnchor(self.alert.contentView.bottomAnchor).active = true
        
        self.downloadStopped = false
        self.downloadErrors = 0
        
        self.alert.addAction(AlertAction(title:"Stop".localized(), style: .Default) { (action) -> Void in
            self.stopDownload()
        })
        
        self.alert.present(animated: false, completion:nil)
    }
    
    @objc private func doDownloadCardData(dummy: AnyObject) {
        let settings = NSUserDefaults.standardUserDefaults()
        let nrdbHost = settings.stringForKey(SettingsKeys.NRDB_HOST)
        let language = settings.stringForKey(SettingsKeys.LANGUAGE)
        
        let cardsUrl = String(format: "http://%@/api/cards/", nrdbHost!)
        let setsUrl = String(format: "http://%@/api/sets/", nrdbHost!)
        
        let userLocale = [ "_locale": language! ]
        let englishLocale = [ "_locale": "en" ]
        
        let cardsRequest = Alamofire.request(.GET, cardsUrl, parameters: userLocale)
        cardsRequest.responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    self.localizedCards = JSON(value)
                }
            case .Failure:
                ++self.downloadErrors
            }
            
            if self.downloadStopped { return }
            
            // get english cards
            let enCardsRequest = Alamofire.request(.GET, cardsUrl, parameters: englishLocale)
            enCardsRequest.responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        self.englishCards = JSON(value)
                    }
                case .Failure:
                    ++self.downloadErrors
                }
                
                if self.downloadStopped { return }
                
                // get sets
                let setsRequest = Alamofire.request(.GET, setsUrl, parameters: userLocale)
                setsRequest.responseJSON { response in
                    switch response.result {
                    case .Success:
                        if let value = response.result.value {
                            self.localizedSets = JSON(value)
                        }
                    case .Failure:
                        ++self.downloadErrors
                    }
                    
                    self.finishDownloads()
                }
            }
        }
    }
    
    private func stopDownload() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.downloadStopped = true
        self.alert = nil
    }
    
    private func finishDownloads() {
        let ok = self.localizedCards != nil
            && self.englishCards != nil
            && self.localizedSets != nil
            && self.downloadErrors == 0
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.alert.dismiss(animated:false) {
            if self.downloadStopped {
                return
            }
            
            if (!ok) {
                UIAlertController.alertWithTitle(nil, message: "Unable to download cards at this time. Please try again later.".localized(), button: "OK")
                return
            } else {
                FIXME()
                CardManager.setupFromNrdbApi(self.localizedCards!)
                CardManager.addAdditionalNames(self.englishCards!, saveFile: true)
//                CardSets.setupFromNrdbApi(self.localizedSets)
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LOAD_CARDS, object:self, userInfo:["success": ok])
            }
        }
        
        self.alert = nil
    }
    
}
