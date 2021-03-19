//
//  DeckImport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 21.02.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit
import SDCAlertView
import Alamofire
import SwiftyUserDefaults

final class DeckImport: NSObject {
    
    private enum DeckBuilderSource {
        case none
        case nrdbList
        case nrdbShared
        case meteor
    }

    private struct DeckSource {
        let deckId: String
        let source: DeckBuilderSource
        let hash: String?

        init(deckId: String, source: DeckBuilderSource, hash: String? = nil) {
            self.deckId = deckId
            self.source = source
            self.hash = hash
        }
    }
    
    static let sharedInstance = DeckImport()
    
    private let importAlways = false // set to true for easier debugging
    
    private var deck: Deck?
    private var deckSource: DeckSource?
    private var uiAlert: UIAlertController?
    private var sdcAlert: AlertController?
    private var downloadStopped: Bool!
    private var request: Request?
 
    static func updateCount() {
        Defaults[.clipChangeCount] = UIPasteboard.general.changeCount
    }
    
    static func checkClipboardForDeck() {
        return sharedInstance.checkClipboardForDeck()
    }
    
    func checkClipboardForDeck() {
        let alwaysImport = BuildConfig.debug ? importAlways : false
        
        let pasteboard = UIPasteboard.general
        let lastChange = Defaults[.clipChangeCount]
        if lastChange == pasteboard.changeCount && !alwaysImport {
            return
        }
        Defaults[.clipChangeCount] = pasteboard.changeCount
        
        guard let clip = pasteboard.string else { return }
        if clip.count == 0 {
            return
        }

        let lines = clip.components(separatedBy: CharacterSet.newlines)
        
        self.deck = nil
        
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
        } else {
            self.deck = self.checkForTextDeck(lines)
            
            if self.deck != nil {
                let msg = "Detected a deck list in your clipboard. Import this deck?".localized()
                self.uiAlert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
            }
        }
        
        if let alert = self.uiAlert {
            alert.addAction(UIAlertAction(title:"No".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title:"Yes".localized(), style: .default) { (UIAlertAction) -> Void in
                Analytics.logEvent(.importFromClipboard)
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
    
    private func checkForNetrunnerDbDeckURL(_ lines: [String]) -> DeckSource? {
        // a netrunnerdb.com decklist url looks like this:
        // https://netrunnerdb.com/en/decklist/3124/in-a-red-dress-and-alone-jamieson-s-store-champ-deck-#
        // or like this:
        // https://netrunnerdb.com/en/deck/view/456867
        // or like this (added hash after the scraping exploit)
        // https://netrunnerdb.com/en/deck/view/456867/hash
        
        let list = try! NSRegularExpression(pattern: "https://netrunnerdb.com/../decklist/(\\d*)/.*", options:[])
        // let shared1 = try! NSRegularExpression(pattern: "https://netrunnerdb.com/../deck/view/(\\d*)/(.*)", options:[])
        let shared2 = try! NSRegularExpression(pattern: "https://netrunnerdb.com/../deck/view/(\\d*)", options:[])
        // FIXME("wip until hashed url format is final")

        let dict = [
            DeckBuilderSource.nrdbShared: [ shared2 ],
            DeckBuilderSource.nrdbList: [ list ]
        ]

        for entry in dict {
            for regex in entry.value {
                for line in lines {
                    if let match = regex.firstMatch(in: line, options:[], range: NSMakeRange(0, line.count)), match.numberOfRanges > 1 {
                        let l = line as NSString
                        let hash = match.numberOfRanges == 3 ? l.substring(with: match.range(at: 2)) : nil
                        let src = DeckSource(deckId: l.substring(with: match.range(at: 1)), source: entry.key, hash: hash)
                        return src
                    }
                }
            }
        }

        return nil
    }
    
    private func checkForMeteorDeckURL(_ lines: [String]) -> DeckSource? {
        // a meteor.stimhack.com decklist url looks like this:
        // https://meteor.stimhack.com/decks/yBMJ3GL6FPozt9nkQ/
        // or like this (no slash)
        // https://meteor.stimhack.com/decks/i6sLkn5cYZ3633WAu
        
        let regEx = try! NSRegularExpression(pattern:"https://meteor.stimhack.com/decks/(.*)/?", options:[])
        
        for line in lines {
            if let match = regEx.firstMatch(in: line, options:[], range:NSMakeRange(0, line.count)) , match.numberOfRanges == 2 {
                let l = line as NSString
                let src = DeckSource(deckId: l.substring(with: match.range(at: 1)), source: .meteor)
                return src
            }
        }
        
        return nil
    }

    private func findMatch(in line: String, regexes: [NSRegularExpression]) -> NSTextCheckingResult? {
        for regex in regexes {
            if let match = regex.firstMatch(in: line, options: [], range: NSMakeRange(0, line.count)) {
                return match
            }
        }
        return nil
    }
    
    private func checkForTextDeck(_ lines: [String]) -> Deck? {
        let cards = CardManager.allCards()

        let regex1 = try! NSRegularExpression(pattern:"^([0-9])x", options:[]) // start with "1x ..."
        let regex2 = try! NSRegularExpression(pattern:" x([0-9])", options:[]) // end with "... x3"
        let regex3 = try! NSRegularExpression(pattern:"^([0-9]) ", options:[]) // start with "1 ..."
        let regexes = [regex1, regex2, regex3]
        
        var name: String?
        let deck = Deck(role: .none)
        for line in lines {
            if name == nil {
                name = line
            }
            
            for var c in cards {
                // don't bother checking cards of the opposite role (as soon as we know this deck's role)
                let roleOk = deck.role == .none || deck.role == c.role
                if !roleOk {
                    continue
                }
                
                let range =
                    line.range(of: c.englishName, options:[.caseInsensitive,.diacriticInsensitive]) ??
                    line.range(of: c.name, options:[.caseInsensitive,.diacriticInsensitive])
                
                if range != nil {
                    if c.type == .identity {
                        deck.addCard(c, copies:1)
                        // NSLog(@"found identity %@", c.name);
                    } else {
                        if let match = self.findMatch(in: line, regexes: regexes), match.numberOfRanges == 2 {
                            let l = line as NSString
                            let count = l.substring(with: match.range(at: 1))
                            // NSLog(@"found card %@ x %@", count, c.name);

                            if Defaults[.useCore2], let newCode = Card.originalToRevised[c.code] {
                                c = CardManager.cardBy(newCode) ?? c
                            }
                            
                            let max = deck.isDraft ? 100 : 4;
                            if let cnt = Int(count), cnt > 0 && cnt < max {
                                deck.addCard(c, copies: cnt)
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
    
    private func downloadDeck(_ source: DeckSource) {
        let alert = AlertController(title: "Downloading Deck".localized(), message: nil, preferredStyle: .alert)
        alert.visualStyle = CustomAlertVisualStyle(alertStyle: .alert)
        self.sdcAlert = alert

        var style = UIActivityIndicatorView.Style.gray
        if #available(iOS 13, *) {
            style = .medium
        }
        let spinner = UIActivityIndicatorView(style: style)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        alert.contentView.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: alert.contentView.centerXAnchor).isActive = true
        spinner.topAnchor.constraint(equalTo: alert.contentView.topAnchor).isActive = true
        spinner.bottomAnchor.constraint(equalTo: alert.contentView.bottomAnchor).isActive = true
        
        alert.addAction(AlertAction(title: "Stop".localized(), style: .normal, handler: { action in
            self.downloadStopped = true
            self.sdcAlert = nil
            if let req = self.request {
                req.cancel()
            }
        }))
        
        alert.present()

        DispatchQueue.main.async {
            switch source.source {
            case .nrdbList:
                self.doDownloadDeckFromNetrunnerDbList(source)

            case .nrdbShared:
                self.doDownloadDeckFromNetrunnerDbShared(source)

            case .meteor:
                self.doDownloadDeckFromMeteor(source)

            case .none:
                break
            }
        }
    }
    
    private func doDownloadDeckFromNetrunnerDbList(_ source: DeckSource) {
        let deckUrl = "https://netrunnerdb.com/api/2.0/public/decklist/" + source.deckId
        self.doDownloadDeckFromNetrunnerDb(deckUrl)
    
    }

    private func doDownloadDeckFromNetrunnerDbShared(_ source: DeckSource) {
        let deckUrl = "https://netrunnerdb.com/api/2.0/public/deck/" + source.deckId
//        if let hash = source.hash {
//            deckUrl += "/" + hash
//        }
        self.doDownloadDeckFromNetrunnerDb(deckUrl)
    }
    
    func doDownloadDeckFromNetrunnerDb(_ deckUrl: String) {
        self.downloadStopped = false
        
        self.request = Alamofire.request(deckUrl).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let data = response.data, !self.downloadStopped {
                    let decks = Deck.arrayFromJson(data)
                    self.downloadFinished(decks.first)
                }
            case .failure(let error):
                print(error)
                self.downloadFinished(nil)
            }
        }
    }
    
    private func doDownloadDeckFromMeteor(_ source: DeckSource) {
        let deckUrl = "https://meteor.stimhack.com/deckexport/octgn/" + source.deckId
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
                    let deck = self.importOctgnDeck(value, name: filename as String)
                    
                    self.downloadFinished(deck)
                }
            case .failure(let error):
                print(error)
                self.downloadFinished(nil)
            }
        })
        
     }

    func importOctgnDeck(_ data: Data, name: String) -> Deck? {
        let importer = OctgnImport()
        if let deck = importer.parseOctgnDeckFromData(data) {
            if deck.identity != nil && deck.cards.count > 0 {
                deck.name = name
                return deck
            }
        }
        return nil
    }

    private func downloadFinished(_ deck: Deck?) {
        self.request = nil
        if let alert = self.sdcAlert {
            alert.dismiss(animated: true) {
                // send notification when dismissal is done
                self.postImportNotification(deck)
            }
        } else {
            self.postImportNotification(deck)
        }
    }

    private func postImportNotification(_ deck: Deck?) {
        if let deck = deck {
            NotificationCenter.default.post(name: Notifications.importDeck, object: self, userInfo: ["deck": deck])
        }
    }
}
