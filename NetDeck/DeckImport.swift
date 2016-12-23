//
//  DeckImport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 21.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import UIKit
import SDCAlertView
import Alamofire
import Marshal

class DeckImport: NSObject {
    
    enum DeckBuilderSource {
        case none
        case nrdbList
        case nrdbShared
        case meteor
    }

    struct DeckSource {
        var deckId: String
        var source: DeckBuilderSource
    }
    
    static let sharedInstance = DeckImport()
    
    static let DEBUG_IMPORT_ALWAYS = false // set to true for easier debugging
    
    var deck: Deck?
    var deckSource: DeckSource?
    var uiAlert: UIAlertController?
    var sdcAlert: AlertController?
    var downloadStopped: Bool!
    var request: Request?
 
    class func updateCount() {
        let c = UIPasteboard.general.changeCount
        UserDefaults.standard.set(c, forKey: SettingsKeys.CLIP_CHANGE_COUNT)
    }
    
    class func checkClipboardForDeck() {
        return sharedInstance.checkClipboardForDeck()
    }
    
    func checkClipboardForDeck() {
        #if DEBUG
            let always = DeckImport.DEBUG_IMPORT_ALWAYS
        #else
            let always = false
        #endif
        
        let pasteboard = UIPasteboard.general
        let lastChange = UserDefaults.standard.integer(forKey: SettingsKeys.CLIP_CHANGE_COUNT)
        if lastChange == pasteboard.changeCount && !always {
            return;
        }
        UserDefaults.standard.set(pasteboard.changeCount, forKey: SettingsKeys.CLIP_CHANGE_COUNT)
        
        guard let clip = pasteboard.string else { return }
        if clip.length == 0 {
            return
        }

        let lines = clip.components(separatedBy: CharacterSet.newlines)
        
        self.deck = nil;
        
        self.deckSource = self.checkForNetrunnerDbDeckURL(lines)
        if self.deckSource == nil {
            self.deckSource = self.checkForMeteorDeckURL(lines)
        }
        
        self.uiAlert = nil
        if let deckSource = self.deckSource {
            switch deckSource.source {
            case .nrdbList, .nrdbShared:
                let msg = "Detected a NetrunnerDB.com deck list URL in your clipboard. Download and import this deck?".localized()
                self.uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                
            case .meteor:
                let msg = "Detected a Meteor deck list URL in your clipboard. Download and import this deck?".localized()
                self.uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                
            default:
                break
            }
        }
        else
        {
            self.deck = self.checkForTextDeck(lines)
            
            if self.deck != nil {
                let msg = "Detected a deck list in your clipboard. Import this deck?".localized()
                self.uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
            }
        }
        
        if let alert = self.uiAlert {
            alert.addAction(UIAlertAction(title:"No".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title:"Yes".localized(), style: .default) { (UIAlertAction) -> Void in
                Analytics.logEvent("Import from Clipboard")
                if self.deck != nil {
                    NotificationCenter.default.post(name: Notifications.importDeck, object:self, userInfo:["deck": self.deck!])
                }
                else if self.deckSource != nil {
                    self.downloadDeck(self.deckSource!)
                }
                self.deck = nil
                self.deckSource = nil
            })
            
            alert.show()
        }
    }
    
    func checkForNetrunnerDbDeckURL(_ lines: [String]) -> DeckSource? {
        // a netrunnerdb.com decklist url looks like this:
        // https://netrunnerdb.com/en/decklist/3124/in-a-red-dress-and-alone-jamieson-s-store-champ-deck-#
        // or like this:
        // https://netrunnerdb.com/en/deck/view/456867
        
        let list = try! NSRegularExpression(pattern: "https://netrunnerdb.com/../decklist/(\\d*)/.*", options:[])
        let shared = try! NSRegularExpression(pattern: "https://netrunnerdb.com/../deck/view/(\\d*)", options:[])
        
        let dict = [
            DeckBuilderSource.nrdbShared: shared,
            DeckBuilderSource.nrdbList: list
        ]
        
        for source in dict.keys {
            let regEx = dict[source]!
            
            for line in lines {
                if let match = regEx.firstMatch(in: line, options:[], range:NSMakeRange(0, line.length)) , match.numberOfRanges == 2 {
                    let l = line as NSString
                    let src = DeckSource(deckId: l.substring(with: match.rangeAt(1)), source: source)
                    return src
                }
            }
        }
        
        return nil
    }
    
    func checkForMeteorDeckURL(_ lines: [String]) -> DeckSource? {
        // a meteor.stimhack.com decklist url looks like this:
        // https://meteor.stimhack.com/decks/yBMJ3GL6FPozt9nkQ/
        // or like this (no slash)
        // https://meteor.stimhack.com/decks/i6sLkn5cYZ3633WAu
        
        let regEx = try! NSRegularExpression(pattern:"https://meteor.stimhack.com/decks/(.*)/?", options:[])
        
        for line in lines {
            if let match = regEx.firstMatch(in: line, options:[], range:NSMakeRange(0, line.length)) , match.numberOfRanges == 2 {
                let l = line as NSString
                let src = DeckSource(deckId: l.substring(with: match.rangeAt(1)), source: .meteor)
                return src
            }
        }
        
        return nil
    }
    
    func checkForTextDeck(_ lines: [String]) -> Deck? {
        let cards = CardManager.allCards()
        let regex1 = try! NSRegularExpression(pattern:"^([0-9])x", options:[]) // start with "1x ..."
        let regex2 = try! NSRegularExpression(pattern:" x([0-9])", options:[]) // end with "... x3"
        let regex3 = try! NSRegularExpression(pattern:"^([0-9]) ", options:[]) // start with "1 ..."
        
        var name: String?
        let deck = Deck(role: .none)
        for line in lines {
            if name == nil {
                name = line
            }
            
            for c in cards {
                // don't bother checking cards of the opposite role (as soon as we know this deck's role)
                let roleOk = deck.role == .none || deck.role == c.role
                if !roleOk {
                    continue
                }
                
                var range = line.range(of: c.englishName, options:[.caseInsensitive,.diacriticInsensitive])
                if range == nil {
                    range = line.range(of: c.name, options:[.caseInsensitive,.diacriticInsensitive])
                }
                
                if range != nil {
                    if c.type == .identity {
                        deck.addCard(c, copies:1)
                        // NSLog(@"found identity %@", c.name);
                    } else {
                        var match = regex1.firstMatch(in: line, options:[], range:NSMakeRange(0, line.length))
                        if match == nil {
                            match = regex2.firstMatch(in: line, options:[], range:NSMakeRange(0, line.length))
                        }
                        if match == nil {
                            match = regex3.firstMatch(in: line, options:[], range:NSMakeRange(0, line.length))
                        }
                        
                        if let m = match , m.numberOfRanges == 2 {
                            let l = line as NSString
                            let count = l.substring(with: m.rangeAt(1))
                            // NSLog(@"found card %@ x %@", count, c.name);
                            
                            let max = deck.isDraft ? 100 : 4;
                            if let cnt = Int(count) , cnt > 0 && cnt < max {
                                deck.addCard(c, copies:cnt)
                            }
                            
                            break
                        }
                    }
                }
            }
        }
        
        if deck.identity != nil && deck.cards.count > 0 {
            deck.name = name ?? ""
            return deck
        } else {
            return nil
        }
    }
    
    func downloadDeck(_ source: DeckSource) {
        
        let alert = AlertController(title: "Downloading Deck".localized(), message: nil, preferredStyle: .alert)
        alert.visualStyle = CustomAlertVisualStyle(alertStyle: .alert)
        self.sdcAlert = alert
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        alert.contentView.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: alert.contentView.centerXAnchor).isActive = true
        spinner.topAnchor.constraint(equalTo: alert.contentView.topAnchor).isActive = true
        spinner.bottomAnchor.constraint(equalTo: alert.contentView.bottomAnchor).isActive = true
        
        alert.add(AlertAction(title: "Stop".localized(), style: .normal, handler: { (action) -> Void in
            self.downloadStopped = true
            self.sdcAlert = nil
            if let req = self.request {
                req.cancel()
            }
        }))
        
        alert.present()
        
        switch source.source {
        case .nrdbList:
            self.perform(#selector(DeckImport.doDownloadDeckFromNetrunnerDbList(_:)), with:source.deckId, afterDelay:0.0)
        
        case .nrdbShared:
            self.perform(#selector(DeckImport.doDownloadDeckFromNetrunnerDbShared(_:)), with:source.deckId, afterDelay:0.0)
        
        default:
            self.perform(#selector(DeckImport.doDownloadDeckFromMeteor(_:)), with:source.deckId, afterDelay:0.0)
        }
    }
    
    func doDownloadDeckFromNetrunnerDbList(_ deckId: String) {
        let deckUrl = "https://netrunnerdb.com/api/2.0/public/decklist/" + deckId
        self.doDownloadDeckFromNetrunnerDb(deckUrl)
    
    }
    func doDownloadDeckFromNetrunnerDbShared(_ deckId: String) {
        let deckUrl = "https://netrunnerdb.com/api/2.0/public/deck/" + deckId
        self.doDownloadDeckFromNetrunnerDb(deckUrl)
    }
    
    func doDownloadDeckFromNetrunnerDb(_ deckUrl: String) {
        var ok = false
        self.downloadStopped = false
        
        self.request = Alamofire.request(deckUrl).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let data = response.data, !self.downloadStopped {
                    do {
                        let json = try JSONParser.JSONObjectWithData(data)
                        // print("JSON: \(json)")
                        ok = self.parseJsonDeckList(json)
                    } catch let error {
                        print("\(error)")
                    }
                }
                self.downloadFinished(ok)
            case .failure(let error):
                print(error)
                self.downloadFinished(false)
            }
        }
    }
    
    func parseJsonDeckList(_ json: JSONObject) -> Bool {
        if !NRDB.validJsonResponse(json: json) {
            return false
        }
        
        do {
            let decks: [Deck] = try json.value(for: "data")
            
            if let deck = decks.first, deck.identity != nil, deck.cards.count > 0 {
                NotificationCenter.default.post(name: Notifications.importDeck, object: self, userInfo: ["deck": deck])
                return true
            }
        } catch let error {
            print("\(error)")
        }
        
        return false
    }

    func doDownloadDeckFromMeteor(_ deckId: String) {
        let deckUrl = "https://meteor.stimhack.com/deckexport/octgn/" + deckId
        var ok = false
        self.downloadStopped = false
        
        self.request = Alamofire.request(deckUrl).responseData(completionHandler: { (response) in
            switch response.result {
            case .success:
                if let value = response.result.value {
                    var filename: NSString = ""
                    if let disposition = response.response?.allHeaderFields["Content-Disposition"] as? NSString {
                        var range = disposition.range(of: "filename=", options: .caseInsensitive)
                        if range.location != NSNotFound {
                            filename = disposition.substring(from: range.location+9) as NSString
                            range = filename.range(of: ".o8d")
                            if range.location != NSNotFound {
                                filename = filename.substring(to: range.location) as NSString
                            }
                            filename = filename.removingPercentEncoding! as NSString
                        }
                    }
                    ok = self.importOctgnDeck(value, name: filename as String)
                    
                    self.downloadFinished(ok)
                }
            case .failure(let error):
                print(error)
                self.downloadFinished(false)
            }
        })
        
     }

    func importOctgnDeck(_ data: Data, name: String) -> Bool {
        let importer = OctgnImport()
        if let deck = importer.parseOctgnDeckFromData(data) {
            if deck.identity != nil && deck.cards.count > 0 {
                deck.name = name
                NotificationCenter.default.post(name: Notifications.importDeck, object: self, userInfo: ["deck": deck])
                return true
            }
        }
        return false
    }

    func downloadFinished(_ ok: Bool) {
        if let alert = self.sdcAlert {
            alert.dismiss()
        }
        self.request = nil
    }

}
