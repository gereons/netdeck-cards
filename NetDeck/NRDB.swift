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
    static let PROVIDER_HOST =  "https://netrunnerdb.com"
    
    static let AUTH_URL =       PROVIDER_HOST + "/oauth/v2/auth?client_id=" + CLIENT_ID + "&response_type=code&redirect_uri=" + CLIENT_HOST
    static let TOKEN_URL =      PROVIDER_HOST + "/oauth/v2/token"
    
    static let FIVE_MINUTES: NSTimeInterval = 300 // in seconds
    
    static let sharedInstance = NRDB()
    override private init() {}
    
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
        settings.setBool(false, forKey: SettingsKeys.USE_NRDB)
        NRDB.clearCredentials()
        
        NRDB.sharedInstance.stopAuthorizationRefresh()
    }
    
    class func clearCredentials() {
        let settings = NSUserDefaults.standardUserDefaults()
        
        settings.removeObjectForKey(SettingsKeys.NRDB_ACCESS_TOKEN)
        settings.removeObjectForKey(SettingsKeys.NRDB_REFRESH_TOKEN)
        settings.removeObjectForKey(SettingsKeys.NRDB_TOKEN_EXPIRY)
        settings.removeObjectForKey(SettingsKeys.NRDB_TOKEN_TTL)
    }
    
    // MARK: - authorization
    
    func authorizeWithCode(code: String, completion: (Bool) -> Void) {
        // NSLog("NRDB authWithCode")
        let parameters = [
            "client_id": NRDB.CLIENT_ID,
            "client_secret": NRDB.CLIENT_SECRET,
            "grant_type": "authorization_code",
            "redirect_uri": NRDB.CLIENT_HOST,
            "code": code
        ]
        
        self.getAuthorization(parameters, isRefresh: false, completion: completion)
    }
    
    private func refreshToken(completion: (Bool) -> Void) {
        // NSLog("NRDB refreshToken")
        guard let token = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_REFRESH_TOKEN) else {
            completion(false)
            return
        }
        
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: SettingsKeys.LAST_REFRESH)
        
        let parameters = [
            "client_id": NRDB.CLIENT_ID,
            "client_secret":  NRDB.CLIENT_SECRET,
            "grant_type": "refresh_token",
            "redirect_uri": NRDB.CLIENT_HOST,
            "refresh_token": token
        ]
        
        self.getAuthorization(parameters, isRefresh: true, completion: completion)
    }
    
    private func getAuthorization(parameters: [String: String], isRefresh: Bool, completion: (Bool) -> Void) {
        
        // NSLog("NRDB get Auth")
        let foreground = UIApplication.sharedApplication().applicationState == .Active
        if foreground && !Reachability.online() {
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
                        
                        if ok {
                            if !settings.boolForKey(SettingsKeys.KEEP_NRDB_CREDENTIALS) {
                                UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
                            }
                            completion(ok)
                        } else {
                            self.handleAuthorizationFailure(isRefresh, completion: completion)
                        }
                    }
                case .Failure:
                    self.handleAuthorizationFailure(isRefresh, completion: completion)
                }
            }
    }
    
    private func handleAuthorizationFailure(isRefresh: Bool, completion: (Bool) -> Void) {
        if !isRefresh {
            NRDB.clearSettings()
            UIAlertController.alertWithTitle(nil, message: "Authorization at NetrunnerDB.com failed".localized(), button: "OK")
            
            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            completion(false)
            return
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.KEEP_NRDB_CREDENTIALS) {
            NRDBHack.sharedInstance.silentlyLogin()
        }
    }
    
    func startAuthorizationRefresh() {
        // NSLog("NRDB startAuthRefresh timer=\(self.timer)")
        let settings = NSUserDefaults.standardUserDefaults()
        
        if !settings.boolForKey(SettingsKeys.USE_NRDB) || self.timer != nil {
            return
        }
        
        if settings.stringForKey(SettingsKeys.NRDB_REFRESH_TOKEN) == nil {
            NRDB.clearSettings()
            return
        }
        
        let expiry = settings.objectForKey(SettingsKeys.NRDB_TOKEN_EXPIRY) as? NSDate ?? NSDate()
        let now = NSDate()
        let diff = expiry.timeIntervalSinceDate(now) - NRDB.FIVE_MINUTES
        // NSLog("start nrdb auth refresh in %f seconds", diff);
        
        self.timer?.invalidate()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(diff, target: self, selector: #selector(NRDB.timedRefresh(_:)), userInfo: nil, repeats: false)
    }
    
    func stopAuthorizationRefresh() {
        // NSLog("NRDB stopAuthRefresh")
        self.timer?.invalidate()
        self.timer = nil
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
    }
    
    func timedRefresh(timer: NSTimer?) {
        // NSLog("NRDB refresh timer callback")
        self.timer = nil
        self.refreshToken { ok in
            if (ok) {
                // schedule next run at 5 minutes before expiry
                let ti = NSUserDefaults.standardUserDefaults().doubleForKey(SettingsKeys.NRDB_TOKEN_TTL) as NSTimeInterval - NRDB.FIVE_MINUTES
                // NSLog("next refresh in %f seconds", ti)
                self.timer = NSTimer.scheduledTimerWithTimeInterval(ti, target: self, selector: #selector(NRDB.timedRefresh(_:)), userInfo: nil, repeats: false)
            }
        }
    }
    
    func backgroundRefreshAuthentication(completion: (UIBackgroundFetchResult) -> Void) {
        // NSLog("NRDB background Refresh")
        let settings = NSUserDefaults.standardUserDefaults()
        if !settings.boolForKey(SettingsKeys.USE_NRDB) {
            // NSLog("no nrdb account");
            completion(.NoData)
            return
        }
        
        if settings.stringForKey(SettingsKeys.NRDB_REFRESH_TOKEN) == nil {
            // NSLog("no token");
            NRDB.clearSettings()
            completion(.NoData)
            return
        }
        
        self.refreshToken { ok in
            // NSLog("refresh: %d", ok);
            completion(ok ? .NewData : .Failed)
        }
    }
    

    private func accessToken() -> String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_ACCESS_TOKEN)
    }
    
    // MARK: - deck lists
    
    func decklist(completion: ([Deck]?) -> Void) {
        let accessToken = self.accessToken() ?? ""
        FIXME("api 2.0")
        let decksUrl = NSURL(string: "https://netrunnerdb.com/api_oauth2/decks?access_token=" + accessToken)!
    
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
        FIXME("api 2.0")
        let loadUrl = NSURL(string: "https://netrunnerdb.com/api_oauth2/load_deck/" + deck.netrunnerDbId! + "?access_token=" + accessToken)!
        
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
        deck.lastModified = NRDB.dateFormatter.dateFromString(json["date_update"].stringValue)
        deck.dateCreated = NRDB.dateFormatter.dateFromString(json["date_creation"].stringValue)
        
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
                let datecreation = entry["date_creation"].string
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
        
        FIXME("api 2.0")
        let saveUrl = "https://netrunnerdb.com/api_oauth2/save_deck/" + deckId
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
        FIXME("api 2.0")
        let publishUrl = "https://netrunnerdb.com/api_oauth2/publish_deck/" + (deck.netrunnerDbId ?? "")
        
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

// NRDB-specific JSON extension

extension JSON {
    
    static private let supportedNrdbApiVersion = 2
    
    // check if this is a valid API response
    var validNrdbResponse: Bool {
        let version = self["version_number"].intValue
        let success = self["success"].boolValue
        return success && version == JSON.supportedNrdbApiVersion
    }
    
    // get a localized property from a "data" object
    func localized(property: String, _ language: String) -> String {
        if let localized = self["_locale"][language][property].string where localized.length > 0 {
            return localized
        } else {
            return self[property].stringValue
        }
    }
}
