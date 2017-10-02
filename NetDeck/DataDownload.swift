//
//  DataDownload.swift
//  NetDeck
//
//  Created by Gereon Steffens on 05.03.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import SDCAlertView
import Alamofire
import Marshal
import SwiftyUserDefaults

private enum DownloadScope: Int {
    case all
    case missing
}

private enum ApiRequest {
    case cycles
    case packs
    case cards
}

class DataDownload: NSObject {
    
    static func downloadCardData(verbose: Bool = true) {
        if verbose {
            self.instance.downloadCardAndSetsData()
        } else {
            self.instance.doDownloadCardData(0)
        }
    }
    
    static func downloadAllImages() {
        self.instance.doDownloadImages(.all)
    }
    
    static func downloadMissingImages() {
        self.instance.doDownloadImages(.missing)
    }
    
    static private let instance = DataDownload()
    
    private var sdcAlert: AlertController?
    private var progressView: UIProgressView?
    private var downloadStopped = false
    private var downloadErrors = 0
    
    private var cards = [Card]()
    
    // MARK: - card and sets download
    
    private func downloadCardAndSetsData() {
        let host = Defaults[.nrdbHost]
        if host.count > 0 {
            self.showDownloadAlert()
            self.perform(#selector(DataDownload.doDownloadCardData(_:)), with: nil, afterDelay: 0.01)
        } else {
            UIAlertController.alert(withTitle: nil, message: "No known NetrunnerDB server".localized(), button: "OK".localized())
            return
        }
    }

    private func showDownloadAlert() {
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
        
        alert.add(AlertAction(title:"Stop".localized(), style: .normal) { action in
            self.stopDownload()
        })
        
        alert.present(animated: false, completion: nil)
    }
    
    private func xrequestFor(_ apiRequest: ApiRequest) -> URLRequest? {
        let nrdbHost = Defaults[.nrdbHost]
        let language = Defaults[.language]
        
        var urlString: String
        switch apiRequest {
        case .cycles: urlString = "https://\(nrdbHost)/api/2.0/public/cycles"
        case .packs: urlString = "https://\(nrdbHost)/api/2.0/public/packs"
        case .cards: urlString = "https://\(nrdbHost)/api/2.0/public/cards"
        }
        
        if language != "en" {
            urlString += "?_locale=\(language)"
        }
        
        if let url = URL(string: urlString) {
            return URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20)
        }
        return nil
    }

    private func requestFor(_ apiRequest: ApiRequest) -> URLRequest? {
        let language = Defaults[.language]

        let urlString: String
        switch apiRequest {
        case .cycles: urlString = "https://gereons.github.io/netdeck-cards/api/2.0/cycles_\(language).json"
        case .packs: urlString = "https://gereons.github.io/netdeck-cards/api/2.0/packs_\(language).json"
        case .cards: urlString = "https://gereons.github.io/netdeck-cards/api/2.0/cards_\(language).json"
        }

        if let url = URL(string: urlString) {
            return URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20)
        }
        return nil
    }
    
    func doDownloadCardData(_ dummy: Any) {
        let requests: [ApiRequest: URLRequest?] = [
            .cycles: self.requestFor(.cycles),
            .packs: self.requestFor(.packs),
            .cards: self.requestFor(.cards),
        ]
        
        let group = DispatchGroup()
        var results = [ApiRequest: Data]()
        
        for req in requests.values {
            if req == nil {
                return
            }
        }
        
        for (key, req) in requests {
            // print("dl for \(key)")
            group.enter()
            Alamofire.request(req!).validate().responseJSON { response in
                switch response.result {
                case .success:
                    if let data = response.data, !self.downloadStopped {
                        results[key] = data
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
            //     print("dl ok for \(a)")
            // }
            let language = Defaults[.language]
            var ok = !self.downloadStopped && results.count == requests.count
            if ok {
                ok = PackManager.setupFromNetrunnerDb(results[.cycles]!, results[.packs]!, language: language)
                // print("packs setup ok=\(ok)")
                if ok {
                    ok = CardManager.setupFromNetrunnerDb(results[.cards]!, language: language)
                    // print("cards setup ok=\(ok)")
                }
                CardManager.setNextDownloadDate()
            }
            
            if let alert = self.sdcAlert {
                alert.dismiss(animated: false) 
                if !ok {
                    let msg = "Unable to download cards at this time. Please try again later.".localized()
                    UIAlertController.alert(withTitle: "Download Error".localized(), message: msg, button: "OK")
                }
            }
            self.sdcAlert = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                NotificationCenter.default.post(name: Notifications.loadCards, object: self, userInfo: ["success": ok])
            }
        }
    }
    
    // MARK: - image download
    
    private func doDownloadImages(_ scope: DownloadScope) {
        self.cards = CardManager.allCards()
        
        if scope == .missing {
            var missing = [Card]()
            for card in self.cards {
                if !ImageCache.sharedInstance.imageAvailable(for: card) {
                    missing.append(card)
                }
            }
            self.cards = missing
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
        
        alert.add(AlertAction(title: "Stop".localized(), style: .normal) { action in
            self.stopDownload()
        })
        
        alert.present(animated: false, completion: nil)
        
        self.downloadStopped = false
        self.downloadErrors = 0
        
        self.downloadImageForCard(0, scope: scope)
    }
    
    private func downloadImageForCard(_ index: Int, scope: DownloadScope) {
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
            } else {
                ImageCache.sharedInstance.updateMissingImage(for: card, completion: downloadNext)
            }
        } else {
            self.sdcAlert?.dismiss(animated:false, completion:nil)
            self.progressView = nil
            self.sdcAlert = nil
            
            self.perform(#selector(self.showMissingCardsAlert), with: nil, afterDelay: 0.05)
        }
    }
    
    func showMissingCardsAlert() {
        if self.downloadErrors > 0 {
            let msg = String(format:"%d of %d images could not be downloaded.".localized(),
                             self.downloadErrors, self.cards.count)
            
            UIAlertController.alert(withTitle: nil, message:msg, button:"OK")
        }
        self.cards.removeAll()
    }
    
    // MARK: - stop downloads
    
    private func stopDownload() {
        self.downloadStopped = true
        self.progressView = nil
        self.sdcAlert = nil
    }

    // MARK: - api checker
    
    static func checkNrdbApi(_ url: String, completion: @escaping (Bool) -> Void) {
        Alamofire.request(url)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    var ok = false
                    if let data = response.data {
                        do {
                            let json = try JSONParser.JSONObjectWithData(data)
                            let total: Int = try json.value(for: "total")
                            ok = NRDB.validJsonResponse(json: json) && total == 1
                        } catch let error {
                            print("\(error)")
                        }
                    }
                    completion(ok)
                case .failure:
                    completion(false)
                }
        }
    }
}
