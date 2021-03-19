//
//  JinetkiNet.swift
//  NetDeck
//
//  Created by Gereon Steffens on 24.07.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Alamofire
import SwiftKeychainWrapper
import SVProgressHUD
import SwiftyUserDefaults

final class JintekiNet {
    static let sharedInstance = JintekiNet()
    
    private let manager: Alamofire.SessionManager
    private let cookieJar: HTTPCookieStorage
    
    private let loginUrl = "https://www.jinteki.net/login"
    private let deckUrl = "https://www.jinteki.net/data/decks"
    
    private init() {
        self.cookieJar = HTTPCookieStorage.shared
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = self.cookieJar
        cfg.httpShouldSetCookies = true
        self.manager = Alamofire.SessionManager(configuration: cfg)
    }
    
    func clearCredentials() {
        let keychain = KeychainWrapper.standard
        keychain.removeObject(forKey: KeychainKeys.jnetUsername)
        keychain.removeObject(forKey: KeychainKeys.jnetPassword)
    }
    
    func clearCookies() {
        // make sure we're not reusing an old session
        if let cookies = self.cookieJar.cookies {
            for cookie in cookies {
                if cookie.name == "connect.sid" {
                    self.cookieJar.deleteCookie(cookie)
                    break
                }
            }
        }
    }
    
    func enterCredentialsAndLogin() {
        let alert = UIAlertController(title: "Jinteki.net Login".localized(), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Username".localized()
            textField.autocorrectionType = .no
            textField.returnKeyType = .next
            textField.enablesReturnKeyAutomatically = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Password".localized()
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
            textField.isSecureTextEntry = true
            textField.enablesReturnKeyAutomatically = true
        }
        
        alert.addAction(UIAlertAction(title: "Login".localized(), style: .default) { [unowned self] action in
            let username = alert.textFields?[0].text ?? ""
            let password = alert.textFields?[1].text ?? ""
            self.testLogin(username, password: password)
            })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        alert.show()
    }
    
    func testLogin(_ username: String, password: String) {
        self.clearCookies()
        let parameters = [
            "username": username,
            "password": password
        ]

        manager.request(loginUrl, method: .post, parameters: parameters).validate().responseJSON { response in
            switch response.result {
            case .success:
                if response.result.value != nil {
                    SVProgressHUD.showSuccess(withStatus: "Logged in".localized())
                    let keychain = KeychainWrapper.standard
                    keychain.set(username, forKey: KeychainKeys.jnetUsername)
                    keychain.set(password, forKey: KeychainKeys.jnetPassword)
                } else {
                    fallthrough
                }
            default:
                SVProgressHUD.showError(withStatus: "Login failed".localized())
                self.clearCredentials()
                Defaults[.useJintekiNet] = false
            }
        }
    }
    
    func uploadDeck(_ deck: Deck) {
        let keychain = KeychainWrapper.standard
        guard
            let username = keychain.string(forKey: KeychainKeys.jnetUsername),
            let password = keychain.string(forKey: KeychainKeys.jnetPassword)
        else {
            return
        }

        self.clearCookies()
        
        let parameters = [
            "username": username,
            "password": password
        ]
        
        manager.request(loginUrl, method: .post, parameters: parameters).validate().responseJSON { response in
            switch response.result {
            case .success:
                if response.result.value != nil {
                    self.postDeckData(deck, username: username)
                } else {
                    fallthrough
                }
            default:
                SVProgressHUD.showError(withStatus: "Login failed".localized())
            }
        }
    }
    
    func postDeckData(_ deck: Deck, username: String) {
        let cards = NSMutableArray()
        for cc in deck.cards {
            let c = NSMutableDictionary()
            c["qty"] = cc.count
            c["card"] = cc.card.name
            cards.add(c)
        }
        
        var id = [String: Any]()
        let identity = deck.identity ?? Card.null()
        
        id["title"] = Card.fullNames[identity.code] ?? identity.name
        id["code"] = identity.code
        id["side"] = identity.role == .runner ? "Runner" : "Corp"
        id["influencelimit"] = identity.influenceLimit
        id["minimumdecksize"] = identity.minimumDecksize
        if identity.role == .runner {
            id["baselink"] = identity.baseLink
        }
        id["faction"] = Faction.fullName(for: identity.faction)
        
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy'-MM'-'dd'T'HH':'mm':'ss'Z'"
        fmt.timeZone = TimeZone(abbreviation: "UTC")
        // 2016-07-19T06:05:52.404Z
        let date = fmt.string(from: deck.lastModified as Date? ?? Date())
        
        let parameters: [String: Any] = [
            "name": deck.name,
            "cards": cards,
            "identity": id,
            "date": date,
            "username": username
        ]
        
        self.manager.request(deckUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
            switch response.result {
            case .success:
                SVProgressHUD.showSuccess(withStatus: "Deck uploaded".localized())
                break
            default:
                SVProgressHUD.showError(withStatus: "Upload failed".localized())
                break
            }
        }
    }
}
