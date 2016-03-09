//
//  NRDB.swift
//  NetDeck
//
//  Created by Gereon Steffens on 07.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Alamofire
import SwiftyJSON

class NRDB: NSObject {
    static let CLIENT_HOST =    "netdeck://oauth2"
    static let CLIENT_ID =      "4_1onrqq7q82w0ow4scww84sw4k004g8cososcg8gog004s4gs08"
    static let CLIENT_SECRET =  "2myhr1ijml6o4kc0wgsww040o8cc84oso80o0w0s44k4k0c84"
    static let PROVIDER_HOST =  "http://netrunnerdb.com"
    
    static let AUTH_URL =       PROVIDER_HOST + "/oauth/v2/auth?client_id=" + CLIENT_ID + "&response_type=code&redirect_uri=" + CLIENT_HOST
    
    static let TOKEN_URL =      PROVIDER_HOST + "/oauth/v2/token"
    
    static let sharedInstance = NRDB()
    
    private static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        formatter.timeZone = NSTimeZone(name: "GMT")
        return formatter
    }()
    
    private var timer: NSTimer?
    private var deckMap = [String: String]()
    
    class func clearSettings() {
        let settings = NSUserDefaults.standardUserDefaults()
        
        settings.removeObjectForKey(SettingsKeys.NRDB_ACCESS_TOKEN)
        settings.removeObjectForKey(SettingsKeys.NRDB_REFRESH_TOKEN)
        settings.removeObjectForKey(SettingsKeys.NRDB_TOKEN_EXPIRY)
        settings.removeObjectForKey(SettingsKeys.NRDB_TOKEN_TTL)
        settings.setBool(false, forKey: SettingsKeys.USE_NRDB)
        
        settings.synchronize()
        NRDB.sharedInstance.timer?.invalidate()
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
    }
    
    // MARK: - authorization
    
    func authorizeWithCode(code: String, completion: (Bool) -> Void) {
        let parameters = [
            "client_id": NRDB.CLIENT_ID,
            "client_secret": NRDB.CLIENT_SECRET,
            "grant_type": "authorization_code",
            "redirect_uri": NRDB.CLIENT_HOST,
            "code": code
        ]
        
        self.getAuthorization(parameters, completion: completion)
    }
    
    private func refreshToken(completion: (Bool) -> Void) {
        guard let token = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_REFRESH_TOKEN) else {
            completion(false)
            return
        }
        
        let parameters = [
            "client_id": NRDB.CLIENT_ID,
            "client_secret":  NRDB.CLIENT_SECRET,
            "grant_type": "refresh_token",
            "redirect_uri": NRDB.CLIENT_HOST,
            "refresh_token": token
        ]
        
        self.getAuthorization(parameters, completion:completion)
    }
    
    private func getAuthorization(parameters: [String: String], completion: (Bool) -> Void) {
        let foreground = UIApplication.sharedApplication().applicationState == .Active
        if foreground && !AppDelegate.online() {
            completion(false)
            return
        }
        
        Alamofire.request(.GET, NRDB.TOKEN_URL, parameters: parameters)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let json = JSON(value)
                        let settings = NSUserDefaults.standardUserDefaults()
                        var ok = true
                        
                        if let token = json["access_token"].string {
                            settings.setObject(token, forKey: SettingsKeys.NRDB_ACCESS_TOKEN)
                        } else {
                            ok = false
                        }
                        
                        if let token = json["refresh_token"].string {
                            settings.setObject(token, forKey: SettingsKeys.NRDB_REFRESH_TOKEN)
                        } else {
                            ok = false
                        }
                        
                        let exp = json["expires_in"].doubleValue
                        settings.setDouble(exp, forKey: SettingsKeys.NRDB_TOKEN_TTL)
                        let expiry = NSDate(timeIntervalSinceNow: exp)
                        settings.setObject(expiry, forKey: SettingsKeys.NRDB_TOKEN_EXPIRY)
                        
                        if !ok {
                            NRDB.clearSettings()
                        } else {
                            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
                            self.refreshAuthentication()
                        }
                        completion(ok)
                    }
                    break
                case .Failure:
                    NRDB.clearSettings()
                    UIAlertController.alertWithTitle(nil, message: "Authorization at NetrunnerDB.com failed".localized(), button: "OK")
                    
                    UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
                    completion(false)
                }
            }
    }
    
    func refreshAuthentication() {
        let settings = NSUserDefaults.standardUserDefaults()
        
        if !settings.boolForKey(SettingsKeys.USE_NRDB) || !AppDelegate.online() {
            return
        }
        
        if settings.stringForKey(SettingsKeys.NRDB_REFRESH_TOKEN) == nil {
            NRDB.clearSettings()
            return
        }
        
        let expiry = settings.objectForKey(SettingsKeys.NRDB_TOKEN_EXPIRY) as? NSDate ?? NSDate()
        let now = NSDate()
        var diff = expiry.timeIntervalSinceDate(now)
        diff -= 5*60; // 5 minutes overlap
        // NSLog(@"start nrdb auth refresh in %f seconds", diff);
        
        if diff < 0 {
            // token is expired, refresh now
            self.timedRefresh(nil)
        } else {
            self.timer?.invalidate()
            self.timer = NSTimer(timeInterval:diff, target:self, selector:"timedRefresh:", userInfo: nil, repeats: false)
        }
    }
    
    func backgroundRefreshAuthentication(completion: (UIBackgroundFetchResult) -> Void) {
        let settings = NSUserDefaults.standardUserDefaults()
        if !settings.boolForKey(SettingsKeys.USE_NRDB) {
            // NSLog(@"no nrdb account");
            completion(.NoData)
            return
        }
        
        if settings.stringForKey(SettingsKeys.NRDB_REFRESH_TOKEN) == nil {
            // NSLog(@"no token");
            NRDB.clearSettings()
            completion(.NoData)
            return
        }
        
        self.refreshToken { ok in
            // NSLog(@"refresh: %d", ok);
            completion(ok ? .NewData : .Failed)
        }
    }
    
    func timedRefresh(timer: NSTimer?) {
        self.refreshToken { ok in
            var ti: NSTimeInterval = 300
            if (ok) {
                ti = NSUserDefaults.standardUserDefaults().doubleForKey(SettingsKeys.NRDB_TOKEN_TTL) as NSTimeInterval
                ti -= 300; // 5 minutes before expiry
            }
            self.timer = NSTimer(timeInterval:ti, target:self, selector:"timedRefresh:", userInfo:nil, repeats: false)
        }
    }
    
    func stopRefresh() {
        self.timer?.invalidate()
        self.timer = nil
    }

    private func accessToken() -> String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_ACCESS_TOKEN)
    }
    
    // MARK: - deck lists
    
    func decklist(completion: ([Deck]?) -> Void) {
        let accessToken = self.accessToken() ?? ""
        let decksUrl = NSURL(string: "http://netrunnerdb.com/api_oauth2/decks?access_token=" + accessToken)!
    
        let request = NSMutableURLRequest(URL: decksUrl, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10)

        Alamofire.request(request).validate().responseJSON { response in
            var decks: [Deck]?
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    decks = self.parseDecksFromJson(json)
                    completion(decks)
                }
            case .Failure:
                completion(nil)
            }
            
            if decks == nil {
                UIAlertController.alertWithTitle(nil, message:"Loading decks from NetrunnerDB.com failed".localized(), button:"OK")
            }
        }
    }
    
    func loadDeck(deck: Deck, completion: (Deck?) -> Void) {
        guard let accessToken = self.accessToken() else {
            completion(nil)
            return
        }
        
        assert(deck.netrunnerDbId != nil, "no nrdb id")
        let loadUrl = NSURL(string: "http://netrunnerdb.com/api_oauth2/load_deck/" + deck.netrunnerDbId! + "?access_token=" + accessToken)!
        
        let request = NSMutableURLRequest(URL: loadUrl, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    let deck = self.parseDeckFromJson(json)
                    completion(deck)
                }
            case .Failure:
                completion(nil)
            }
        }
    }
    
    func parseDecksFromJson(json: JSON) -> [Deck] {
        var decks = [Deck]()
        for d in json.arrayValue {
            if let deck = self.parseDeckFromJson(d) {
                decks.append(deck)
            }
        }
        return decks
    }
    
    func parseDeckFromJson(json: JSON) -> Deck? {
        let deck = Deck()
        
        deck.name = json["name"].string
        deck.notes = json["description"].string
        deck.tags = json["tags"].arrayObject as? [String]
        deck.netrunnerDbId = "\(json["id"].intValue)"
        
        // parse last update '2014-06-19T13:52:24Z'
        deck.lastModified = NRDB.dateFormatter.dateFromString(json["dateupdate"].stringValue)
        deck.dateCreated = NRDB.dateFormatter.dateFromString(json["datecreation"].stringValue)
        
        for c in json["cards"].arrayValue {
            let code = c["card_code"].stringValue
            let qty = c["qty"].int
            
            let card = CardManager.cardByCode(code)
            if card != nil && qty != nil {
                deck.addCard(card!, copies:qty!, history: false)
            }
        }
        
        var revisions = [DeckChangeSet]()
        if let history = json["history"].array {
            for entry in history {
                let datecreation = entry["datecreation"].string
                let dcs = DeckChangeSet()
                dcs.timestamp = NRDB.dateFormatter.dateFromString(datecreation ?? "")
                
                let variation = entry["variation"].arrayValue
                
                for i in 0..<variation.count {
                    let mult = i==0 ? 1 : -1
                    let v = variation[i]
                    if v.type == .Dictionary {
                        for (code, qty):(String,JSON) in v {
                            let amount = mult * qty.intValue
                            if let _ = CardManager.cardByCode(code) {
                                dcs.addCardCode(code, copies: amount)
                            }
                        }
                    }
                }
                
                dcs.sort()
                revisions.append(dcs)
            }
        }
        
        let initial = DeckChangeSet()
        initial.initial = true
        initial.timestamp = deck.dateCreated
        revisions.append(initial)
        deck.revisions = revisions
        
        let newest = deck.revisions.first
        var cards = [String: Int]()
        for cc in deck.allCards {
            cards[cc.card.code] = cc.count
        }
        newest?.cards = cards
        
        // walk through the deck's history and pre-compute a card list for every revision
        for i in 0..<deck.revisions.count-1 {
            let prev = deck.revisions[i]
            for dc in prev.changes {
                let qty = (cards[dc.code] ?? 0) - dc.count
                if qty == 0 {
                    cards.removeValueForKey(dc.code)
                } else {
                    cards[dc.code] = qty
                }
            }
            
            let dcs = deck.revisions[i+1]
            dcs.cards = cards
        }
        
        return deck
    }
    
    // MARK: - save / publish
    
    func saveDeck(deck: Deck, completion: (Bool, String?) -> Void) {
        guard let accessToken = self.accessToken() else {
            completion(false, nil)
            return
        }
        
        let cards = NSMutableArray()
        if let id = deck.identity {
            let c = [ "card_code": id.code, "qty": 1 ]
            cards.addObject(c)
        }
        for cc in deck.cards {
            let c = [ "card_code": cc.card.code, "qty": cc.count ]
            cards.addObject(c)
        }
        let json = JSON(cards)
        
        let deckId = deck.netrunnerDbId ?? "0"
        
        let saveUrl = "http://netrunnerdb.com/api_oauth2/save_deck/" + deckId
        var parameters = [
            "access_token": accessToken,
            "content": json.rawString() ?? ""
        ]
        if let notes = deck.notes {
            parameters["description"] = notes
        }
        if let name = deck.name {
            parameters["name"] = name
        }
        if deckId != "0" {
            parameters["id"] = deckId
        }
        if let tags = deck.tags {
            parameters["tags"] = (tags as NSArray).componentsJoinedByString(" ")
        }
        
        self.saveOrPublish(saveUrl, parameters: parameters, completion: completion)
    }
    
    func publishDeck(deck: Deck, completion: (Bool, String?) -> Void) {
        let publishUrl = "http://netrunnerdb.com/api_oauth2/publish_deck/" + (deck.netrunnerDbId ?? "")
        
        let accessToken = self.accessToken()
        let parameters = [
            "access_token": accessToken ?? ""
        ]
        
        self.saveOrPublish(publishUrl, parameters:parameters, completion: completion)
    }
    
    func saveOrPublish(url: String, parameters: [String:String], completion: (Bool, String?)->Void) {
        
        Alamofire.request(.GET, url, parameters: parameters).validate().responseJSON { response in
            switch response.result {
            case .Success(let value):
                let json = JSON(value)
                let ok = json["success"].boolValue
                if ok {
                    let deckId = json["message"]["id"].stringValue
                    if deckId != "" {
                        completion(true, deckId)
                        return
                    }
                }
            case .Failure:
                break
            }
            completion(false, nil)
        }
    }
    
    // MARK: - mapping of nrdb ids to filenames
    
    func updateDeckMap(decks: [Deck]) {
        self.deckMap = [String: String]()
        for deck in decks {
            if let filename = deck.filename, nrdbId = deck.netrunnerDbId {
                self.deckMap[nrdbId] = filename
            }
        }
    }
    
    func filenameForId(deckId: String?) -> String? {
        return self.deckMap[deckId ?? ""]
    }
    
    func deleteDeck(deckId: String?) {
        self.deckMap.removeValueForKey(deckId ?? "")
    }
}
