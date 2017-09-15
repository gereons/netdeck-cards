//
//  NRDB.swift
//  NetDeck
//
//  Created by Gereon Steffens on 07.03.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Alamofire
import Marshal
import SwiftyUserDefaults

class NRDB: NSObject {
    static let clientHost =    "netdeck://oauth2"
    static let clientId =      "4_1onrqq7q82w0ow4scww84sw4k004g8cososcg8gog004s4gs08"
    static let clientSecret =  "2myhr1ijml6o4kc0wgsww040o8cc84oso80o0w0s44k4k0c84"
    static let providerHost =  "https://netrunnerdb.com"
    
    static let authUrl =       providerHost + "/oauth/v2/auth?client_id=" + clientId + "&response_type=code&redirect_uri=" + clientHost
    static let tokenUrl =      providerHost + "/oauth/v2/token"
    
    static let fiveMinutes: TimeInterval = 300 // in seconds
    
    static let sharedInstance = NRDB()
    override private init() {}
    
    private var timer: Timer?
    private var deckMap = [String: String]()
    
    static func clearSettings() {
        Defaults[.useNrdb] = false
        
        Defaults.remove(.nrdbAccessToken)
        Defaults.remove(.nrdbRefreshToken)
        Defaults.remove(.nrdbTokenExpiry)
        Defaults.remove(.nrdbTokenTTL)
        
        NRDB.sharedInstance.stopAuthorizationRefresh()
    }
    
    // MARK: - authorization
    
    func authorizeWithCode(_ code: String, completion: @escaping (Bool) -> Void) {
        // print("NRDB authWithCode")
        let parameters = [
            "client_id": NRDB.clientId,
            "client_secret": NRDB.clientSecret,
            "grant_type": "authorization_code",
            "redirect_uri": NRDB.clientHost,
            "code": code
        ]
        
        self.getAuthorization(parameters, isRefresh: false, completion: completion)
    }
    
    private func refreshToken(_ completion: @escaping (Bool) -> Void) {
        // print("NRDB refreshToken")
        
        guard let token = Defaults[.nrdbRefreshToken] else {
            completion(false)
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        Defaults[.lastRefresh] = formatter.string(from: Date())
        
        let parameters = [
            "client_id": NRDB.clientId,
            "client_secret":  NRDB.clientSecret,
            "grant_type": "refresh_token",
            "redirect_uri": NRDB.clientHost,
            "refresh_token": token
        ]
        
        self.getAuthorization(parameters, isRefresh: true, completion: completion)
    }
    
    private func getAuthorization(_ parameters: [String: String], isRefresh: Bool, completion: @escaping (Bool) -> Void) {
        
        // print("NRDB get Auth")
        let foreground = UIApplication.shared.applicationState == .active
        if foreground && !Reachability.online {
            completion(false)
            return
        }

        Alamofire.request(NRDB.tokenUrl, parameters: parameters)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let data = response.data {
                        var ok = true
                        do {
                            let json = try JSONParser.JSONObjectWithData(data)
                            
                            let accessToken: String = try json.value(for: "access_token")
                            Defaults[.nrdbAccessToken] = accessToken
                            
                            let refreshToken: String = try json.value(for: "refresh_token")
                            Defaults[.nrdbRefreshToken] = refreshToken
                            
                            let exp: Double = try json.value(for: "expires_in")
                            Defaults[.nrdbTokenTTL] = exp
                            let expiry = Date(timeIntervalSinceNow: exp)
                            Defaults[.nrdbTokenExpiry] = expiry
                        } catch let error {
                            print("auth error: bad json: \(error)")
                            ok = false
                        }
                        if ok {
                            if !Defaults[.keepNrdbCredentials] {
                                UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
                            }
                            completion(ok)
                        } else {
                            self.handleAuthorizationFailure(isRefresh, completion: completion)
                        }
                    } else {
                        print("auth error: no data")
                    }
                case .failure:
                    print("auth error \(String(describing: response.response?.statusCode))")
                    if let data = response.data {
                        let body = String(data: data, encoding: .utf8)
                        print("body: \(String(describing: body))")
                    }
                    self.handleAuthorizationFailure(isRefresh, completion: completion)
                }
            }
    }
    
    private func handleAuthorizationFailure(_ isRefresh: Bool, completion: (Bool) -> Void) {
        NRDB.clearSettings()
        if !isRefresh {
            UIAlertController.alert(withTitle: nil, message: "Authorization at NetrunnerDB.com failed".localized(), button: "OK")
            
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            completion(false)
            return
        }

        if Defaults[.keepNrdbCredentials] {
            NRDBHack.sharedInstance.silentlyLogin()
        }
    }
    
    func startAuthorizationRefresh() {
        // print("NRDB startAuthRefresh timer=\(self.timer)")
        
        if !Defaults[.useNrdb] || self.timer != nil {
            return
        }
        
        if Defaults[.nrdbRefreshToken] == nil {
            return
        }
        
        if NRDBHack.sharedInstance.loggingIn {
            return
        }
        
        let expiry = Defaults[.nrdbTokenExpiry] ?? Date()
        let now = Date()
        let diff = expiry.timeIntervalSince(now) - NRDB.fiveMinutes
        // print("start nrdb auth refresh in \(diff) seconds");
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: diff, target: self, selector: #selector(NRDB.timedRefresh(_:)), userInfo: nil, repeats: false)
    }
    
    func stopAuthorizationRefresh() {
        // print("NRDB stopAuthRefresh")
        self.timer?.invalidate()
        self.timer = nil
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
    }
    
    @objc func timedRefresh(_ timer: Timer?) {
        // print("NRDB refresh timer callback")
        self.timer = nil
        self.refreshToken { ok in
            if ok {
                // schedule next run at 5 minutes before expiry
                let ti = Defaults[.nrdbTokenTTL] - NRDB.fiveMinutes
                // print("next refresh in \(ti) seconds")
                self.timer = Timer.scheduledTimer(timeInterval: ti, target: self, selector: #selector(NRDB.timedRefresh(_:)), userInfo: nil, repeats: false)
            }
        }
    }
    
    func backgroundRefreshAuthentication(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        // print("NRDB background Refresh")
        if !Defaults[.useNrdb] {
            print("no nrdb account");
            completion(.noData)
            return
        }
        
        if Defaults[.nrdbRefreshToken] == "" {
            // print("no token");
            NRDB.clearSettings()
            completion(.noData)
            return
        }
        
        self.refreshToken { ok in
            // print("refresh ok \(ok)")
            completion(ok ? .newData : .failed)
        }
    }
    

    private func accessToken() -> String? {
        return Defaults[.nrdbAccessToken]
    }
    
    // MARK: - deck lists
    
    func decklist(_ completion: @escaping ([Deck]?) -> Void) {
        let accessToken = self.accessToken() ?? ""
        let decksUrl = URL(string: "https://netrunnerdb.com/api/2.0/private/decks?access_token=" + accessToken)!
    
        let request = URLRequest(url: decksUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)

        Alamofire.request(request).validate().responseJSON { response in
            var decks: [Deck]?
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let json = try JSONParser.JSONObjectWithData(data)
                        decks = self.parseDecksFromJson(json)
                        completion(decks)
                    } catch {
                        completion(nil)
                    }
                }
            case .failure:
                completion(nil)
            }
            
            if decks == nil {
                UIAlertController.alert(withTitle: nil, message:"Loading decks from NetrunnerDB.com failed".localized(), button:"OK".localized())
            }
        }
    }
    
    func loadDeck(_ deckId: String, completion: @escaping (Deck?) -> Void) {
        guard let accessToken = self.accessToken() else {
            completion(nil)
            return
        }
        
        let loadUrl = URL(string: "https://netrunnerdb.com/api/2.0/private/deck/" + deckId + "?include_history=1&access_token=" + accessToken)!
        
        let request = URLRequest(url: loadUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let json = try JSONParser.JSONObjectWithData(data)
                        let deck = self.parseDeckFromJson(json)
                        completion(deck)
                    } catch {
                        completion(nil)
                    }
                }
            case .failure:
                completion(nil)
            }
        }
    }
    
    private func parseDecksFromJson(_ json: JSONObject) -> [Deck] {
        var decks = [Deck]()
        
        if !NRDB.validJsonResponse(json: json) {
            return decks
        }
        
        do {
            decks = try json.value(for: "data")
        } catch let error {
            print("caught \(error)")
        }
        return decks
    }
    
    private func parseDeckFromJson(_ json: JSONObject) -> Deck? {
        if !NRDB.validJsonResponse(json: json) {
            return nil
        }
        do {
            let decks: [Deck] = try json.value(for: "data")
            return decks.first
        } catch {}
    
        return nil
    }
    
    // MARK: - save / publish
    
    func saveDeck(_ deck: Deck, completion: @escaping (Bool, String?, String?) -> Void) {
        guard let accessToken = self.accessToken() else {
            completion(false, nil, nil)
            return
        }
        
        var cards = [String: Int]()
        if let id = deck.identity {
            cards[id.code] = 1
        }
        for cc in deck.cards {
            cards[cc.card.code] = cc.count
        }
        
        let saveUrl = "https://netrunnerdb.com/api/2.0/private/deck/save?access_token=" + accessToken
        let deckId = deck.netrunnerDbId ?? "0"
        let parameters: [String: Any] = [
            "deck_id": deckId,
            "name": deck.name,
            "description": deck.notes ?? "",
            "content": cards
        ]
        
        self.saveOrPublish(saveUrl, parameters: parameters, completion: completion)
    }
    
    func publishDeck(_ deck: Deck, completion: @escaping (Bool, String?, String?) -> Void) {
        guard let accessToken = self.accessToken() else {
            completion(false, nil, nil)
            return
        }
        
        let publishUrl = "https://netrunnerdb.com/api/2.0/private/deck/publish?access_token=" + accessToken
        
        let parameters = [
            "deck_id": deck.netrunnerDbId ?? "0",
            "name": deck.name
        ]
        
        self.saveOrPublish(publishUrl, parameters:parameters, completion: completion)
    }

    func saveOrPublish(_ url: String, parameters: [String: Any], completion: @escaping (Bool, String?, String?)->Void) {
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let data = response.data {
                        do {
                            let json = try JSONParser.JSONObjectWithData(data)
                            let ok = NRDB.validJsonResponse(json: json)
                            if ok {
                                let decks: [Deck] = try json.value(for: "data")
                                
                                if let deck = decks.first, deck.netrunnerDbId != "" {
                                    completion(true, deck.netrunnerDbId, nil)
                                    return
                                }
                            } else {
                                let msg: String = try json.value(for: "msg")
                                completion(false, nil, msg)
                                return
                            }
                        } catch {
                            break
                        }
                    }
                case .failure:
                    break
                }
                completion(false, nil, nil)
            }
    }
    
    // MARK: - mapping of nrdb ids to filenames
    
    func updateDeckMap(_ decks: [Deck]) {
        self.deckMap.removeAll()
        for deck in decks {
            self.addDeck(deck)
        }
    }
    
    func addDeck(_ deck: Deck) {
        if let filename = deck.filename, let nrdbId = deck.netrunnerDbId {
            self.deckMap[nrdbId] = filename
        }
    }
    
    func filenameForId(_ deckId: String?) -> String? {
        return self.deckMap[deckId ?? ""]
    }
    
    func deleteDeck(_ deckId: String?) {
        self.deckMap.removeValue(forKey: deckId ?? "")
    }
    
    static private let supportedNrdbApiVersion = "2.0"
    static func validJsonResponse(json: JSONObject) -> Bool {
        do {
            let version: String = try json.value(for: "version_number")
            let success: Bool = try json.value(for: "success")
            let total: Int = try json.value(for: "total")
            return success && version == supportedNrdbApiVersion && total > 0
        } catch {
            return false
        }
    }
}

// MARK: - NRDB-specific JSON extension

extension MarshaledObject {
    /// try to get a localized property for `key`
    func localized(for key: KeyType, language: String) throws -> String {
        if let loc: String = try? self.value(for: "_locale." + language + "." + key.stringValue), loc.length > 0 {
            return loc
        } else {
            return try self.value(for: key) ?? ""
        }
    }
}
