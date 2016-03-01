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
import SwiftyJSON

class DeckImport: NSObject {
    
    enum DeckBuilderSource {
        case None
        case NRDBList
        case NRDBShared
        case Meteor
    }

    struct DeckSource {
        var deckId: String
        var source: DeckBuilderSource
    }
    
    static let sharedInstance = DeckImport()
    
    static let DEBUG_IMPORT_ALWAYS = true // set to true for easier debugging
    
    var deck: Deck?
    var deckSource: DeckSource?
    var uiAlert: UIAlertController?
    var sdcAlert: AlertController?
    var downloadStopped: Bool!
    var request: Request?
 
    class func updateCount() {
        let c = UIPasteboard.generalPasteboard().changeCount
        NSUserDefaults.standardUserDefaults().setInteger(c, forKey: SettingsKeys.CLIP_CHANGE_COUNT)
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
        
        let pasteboard = UIPasteboard.generalPasteboard()
        let lastChange = NSUserDefaults.standardUserDefaults().integerForKey(SettingsKeys.CLIP_CHANGE_COUNT)
        if lastChange == pasteboard.changeCount && !always {
            return;
        }
        NSUserDefaults.standardUserDefaults().setInteger(pasteboard.changeCount, forKey: SettingsKeys.CLIP_CHANGE_COUNT)
        
        guard let clip = pasteboard.string else { return }
        if clip.length == 0 {
            return
        }

        let lines = clip.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        self.deck = nil;
        
        self.deckSource = self.checkForNetrunnerDbDeckURL(lines)
        if self.deckSource == nil {
            self.deckSource = self.checkForMeteorDeckURL(lines)
        }
        
        self.uiAlert = nil
        if let deckSource = self.deckSource {
            switch deckSource.source {
            case .NRDBList, .NRDBShared:
                let msg = "Detected a NetrunnerDB.com deck list URL in your clipboard. Download and import this deck?".localized()
                self.uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
                
            case .Meteor:
                let msg = "Detected a meteor deck list URL in your clipboard. Download and import this deck?".localized()
                self.uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
                
            default:
                break
            }
        }
        else
        {
            self.deck = self.checkForTextDeck(lines)
            
            if self.deck != nil {
                let msg = "Detected a deck list in your clipboard. Import this deck?".localized()
                self.uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
            }
        }
        
        if let alert = self.uiAlert {
            alert.addAction(UIAlertAction(title:"No".localized(), style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title:"Yes".localized(), style: .Default) { (UIAlertAction) -> Void in
                if self.deck != nil {
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.IMPORT_DECK, object:self, userInfo:["deck": self.deck!])
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
    
    func checkForNetrunnerDbDeckURL(lines: [String]) -> DeckSource? {
        // a netrunnerdb.com decklist url looks like this:
        // http://netrunnerdb.com/en/decklist/3124/in-a-red-dress-and-alone-jamieson-s-store-champ-deck-#
        // or like this:
        // http://netrunnerdb.com/en/deck/view/456867
        
        let list = try! NSRegularExpression(pattern: "http://netrunnerdb.com/../decklist/(\\d*)/.*", options:[])
        let shared = try! NSRegularExpression(pattern: "http://netrunnerdb.com/../deck/view/(\\d*)", options:[])
        
        let dict = [
            DeckBuilderSource.NRDBShared: shared,
            DeckBuilderSource.NRDBList: list
        ]
        
        for source in dict.keys {
            let regEx = dict[source]!
            
            for line in lines {
                if let match = regEx.firstMatchInString(line, options:[], range:NSMakeRange(0, line.length)) where match.numberOfRanges == 2 {
                    let l = line as NSString
                    let src = DeckSource(deckId: l.substringWithRange(match.rangeAtIndex(1)), source: source)
                    return src
                }
            }
        }
        
        return nil
    }
    
    func checkForMeteorDeckURL(lines: [String]) -> DeckSource? {
        // a netrunner.meteor.com decklist url looks like this:
        // http://netrunner.meteor.com/decks/yBMJ3GL6FPozt9nkQ/
        // or like this (no slash)
        // http://netrunner.meteor.com/decks/i6sLkn5cYZ3633WAu
        
        let regEx = try! NSRegularExpression(pattern:"http://netrunner.meteor.com/decks/(.*)/?", options:[])
        
        for line in lines {
            if let match = regEx.firstMatchInString(line, options:[], range:NSMakeRange(0, line.length)) where match.numberOfRanges == 2 {
                let l = line as NSString
                let src = DeckSource(deckId: l.substringWithRange(match.rangeAtIndex(1)), source: .Meteor)
                return src
            }
        }
        
        return nil
    }
    
    func checkForTextDeck(lines: [String]) -> Deck? {
        let cards = CardManager.allCards()
        let regex1 = try! NSRegularExpression(pattern:"^([0-9])x", options:[]) // start with "1x ..."
        let regex2 = try! NSRegularExpression(pattern:" x([0-9])", options:[]) // end with "... x3"
        let regex3 = try! NSRegularExpression(pattern:"^([0-9]) ", options:[]) // start with "1 ..."
        
        var name: String?
        let deck = Deck()
        var role = NRRole.None
        for line in lines {
            if name == nil {
                name = line
            }
            
            for c in cards {
                // don't bother checking cards of the opposite role (as soon as we know this deck's role)
                let roleOk = role == .None || role == c.role;
                if !roleOk {
                    continue
                }
                
                var range = line.rangeOfString(c.name_en, options:[.CaseInsensitiveSearch,.DiacriticInsensitiveSearch])
                if range == nil {
                    range = line.rangeOfString(c.name, options:[.CaseInsensitiveSearch,.DiacriticInsensitiveSearch])
                }
                
                if range != nil {
                    if c.type == .Identity {
                        deck.addCard(c, copies:1)
                        role = c.role
                        // NSLog(@"found identity %@", c.name);
                    } else {
                        var match = regex1.firstMatchInString(line, options:[], range:NSMakeRange(0, line.length))
                        if match == nil {
                            match = regex2.firstMatchInString(line, options:[], range:NSMakeRange(0, line.length))
                        }
                        if match == nil {
                            match = regex3.firstMatchInString(line, options:[], range:NSMakeRange(0, line.length))
                        }
                        
                        if let m = match where m.numberOfRanges == 2 {
                            let l = line as NSString
                            let count = l.substringWithRange(m.rangeAtIndex(1))
                            // NSLog(@"found card %@ x %@", count, c.name);
                            
                            let max = deck.isDraft ? 100 : 4;
                            if let cnt = Int(count) where cnt > 0 && cnt < max {
                                deck.addCard(c, copies:cnt)
                            }
                            
                            break
                        }
                    }
                }
            }
        }
        
        if deck.identity != nil && deck.cards.count > 0 {
            deck.name = name
            return deck
        } else {
            return nil
        }
    }
    
    func downloadDeck(source: DeckSource) {
        
        let alert = AlertController(title: "Downloading Deck".localized(), message: nil, preferredStyle: .Alert)
        self.sdcAlert = alert
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        alert.contentView.addSubview(spinner)
        
        spinner.centerXAnchor.constraintEqualToAnchor(alert.contentView.centerXAnchor).active = true
        spinner.topAnchor.constraintEqualToAnchor(alert.contentView.topAnchor).active = true
        spinner.bottomAnchor.constraintEqualToAnchor(alert.contentView.bottomAnchor).active = true
        
        alert.addAction(AlertAction(title: "Stop".localized(), style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.downloadStopped = true
            self.sdcAlert = nil
            if let req = self.request {
                req.cancel()
            }
        }))
        
        alert.present()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        switch source.source {
        case .NRDBList:
            self.performSelector("doDownloadDeckFromNetrunnerDbList:", withObject:source.deckId, afterDelay:0.01)
        
        case .NRDBShared:
            self.performSelector("doDownloadDeckFromNetrunnerDbShared:", withObject:source.deckId, afterDelay:0.01)
        
        default:
            self.performSelector("doDownloadDeckFromMeteor:", withObject:source.deckId, afterDelay:0.01)
        }
    }
    
    func doDownloadDeckFromNetrunnerDbList(deckId: String) {
        let deckUrl = "http://netrunnerdb.com/api/decklist/" + deckId
        self.doDownloadDeckFromNetrunnerDb(deckUrl)
    }
    
    func doDownloadDeckFromNetrunnerDbShared(deckId: String) {
        let deckUrl = "http://netrunnerdb.com/api/shareddeck/" + deckId
        self.doDownloadDeckFromNetrunnerDb(deckUrl)
    }
    
    func doDownloadDeckFromNetrunnerDb(deckUrl: String) {
        var ok = false
        self.downloadStopped = false
        
        self.request = Alamofire.request(.GET, deckUrl).validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value where !self.downloadStopped {
                    let json = JSON(value)
                    // print("JSON: \(json)")
                    ok = self.parseJsonDeckList(json)
                }
                self.downloadFinished(ok)
            case .Failure(let error):
                print(error)
                self.downloadFinished(false)
            }
        }
    }
    
    func parseJsonDeckList(json: JSON) -> Bool {
        let deck = Deck()
        
        deck.name = json["name"].stringValue
        var notes = json["description"].stringValue
        if notes.length > 0 {
            notes = notes.stringByReplacingOccurrencesOfString("<p>", withString: "")
            notes = notes.stringByReplacingOccurrencesOfString("</p>", withString: "")
            deck.notes = notes
        }
        
        let cards = json["cards"].dictionaryValue
        for code in cards.keys {
            let qty = cards[code]!.intValue
            if let card = CardManager.cardByCode(code) where qty > 0 {
                if card.type == .Identity {
                    deck.role = card.role
                }
                deck.addCard(card, copies: qty)
            }
        }
        
        if deck.identity != nil && deck.cards.count > 0 {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.IMPORT_DECK, object: self, userInfo: ["deck": deck])
            return true
        }
        return false
    }

    func doDownloadDeckFromMeteor(deckId: String) {
        let deckUrl = "http://netrunner.meteor.com/deckexport/octgn/" + deckId
        var ok = false
        self.downloadStopped = false
        
        self.request = Alamofire.request(.GET, deckUrl).responseData({ (response) -> Void in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    var filename: NSString = ""
                    if let disposition = response.response?.allHeaderFields["Content-Disposition"] {
                        var range = disposition.rangeOfString("filename=", options: .CaseInsensitiveSearch)
                        if range.location != NSNotFound {
                            filename = disposition.substringFromIndex(range.location+9)
                            range = filename.rangeOfString(".o8d")
                            if range.location != NSNotFound {
                                filename = filename.substringToIndex(range.location)
                            }
                            filename = filename.stringByRemovingPercentEncoding!
                        }
                    }
                    ok = self.importOctgnDeck(value, name: filename as String)
                    
                    self.downloadFinished(ok)
                }
            case .Failure(let error):
                print(error)
                self.downloadFinished(false)
            }
        })
        
     }

    func importOctgnDeck(data: NSData, name: String) -> Bool {
        let importer = OctgnImport()
        if let deck = importer.parseOctgnDeckFromData(data) {
            if deck.identity != nil && deck.cards.count > 0 {
                deck.name = name
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.IMPORT_DECK, object: self, userInfo: ["deck": deck])
                return true
            }
        }
        return false
    }

    func downloadFinished(ok: Bool) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if let alert = self.sdcAlert {
            alert.dismiss()
        }
        self.request = nil
    }

    class func importDeckFromLocalUrl(url: NSURL) {
        let path = url.path!
        let b64 = path.substringFromIndex(path.startIndex.advancedBy(1)) // strip off the leading "/" character
        let data = NSData(base64EncodedString: b64, options: [])
        let uncompressed = GZip.gzipDeflate(data)
        let deckStr = NSString(data: uncompressed, encoding: NSUTF8StringEncoding)
        
        let deck = Deck()
        if let parts = deckStr?.componentsSeparatedByString("&") {
            for card in parts {
                let arr = card.componentsSeparatedByString("=")
                let code = arr[0]
                let qty = arr[1]
                
                if code == "name" {
                    deck.name = qty
                } else {
                    if let card = CardManager.cardByCode(code), q = Int(qty) where q > 0 {
                        deck.addCard(card, copies: q)
                    }
                }
            }
        }
        
        if deck.identity != nil && deck.cards.count > 0 {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.IMPORT_DECK, object: self, userInfo: ["deck": deck])
        }
    }
}
