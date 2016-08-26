//
//  JinetkiNet.swift
//  NetDeck
//
//  Created by Gereon Steffens on 24.07.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Alamofire
import SwiftKeychainWrapper
import SVProgressHUD
import SwiftyJSON

class JintekiNet: NSObject {
    static let sharedInstance = JintekiNet()
    
    private let manager: Alamofire.Manager
    private let cookieJar: NSHTTPCookieStorage
    
    let loginUrl = "http://www.jinteki.net/login"
    let deckUrl = "http://www.jinteki.net/data/decks"
    
    override private init() {
        self.cookieJar = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
        cfg.HTTPCookieStorage = self.cookieJar
        cfg.HTTPShouldSetCookies = true
        self.manager = Alamofire.Manager(configuration: cfg)
    }
    
    func clearCredentials() {
        let keychain = KeychainWrapper.defaultKeychainWrapper()
        keychain.removeObjectForKey(SettingsKeys.JNET_USERNAME)
        keychain.removeObjectForKey(SettingsKeys.JNET_PASSWORD)
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
        let alert = UIAlertController(title: "Jinteki.net Login".localized(), message: nil, preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "Username".localized()
            textField.autocorrectionType = .No
            textField.returnKeyType = .Next
            textField.enablesReturnKeyAutomatically = true
        }
        
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "Password".localized()
            textField.autocorrectionType = .No
            textField.returnKeyType = .Done
            textField.secureTextEntry = true
            textField.enablesReturnKeyAutomatically = true
        }
        
        alert.addAction(UIAlertAction(title: "Login".localized(), style: .Default) { action in
            let username = alert.textFields?[0].text ?? ""
            let password = alert.textFields?[1].text ?? ""
            self.testLogin(username, password: password)
            })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .Cancel, handler: nil))
        
        alert.show()
    }
    
    func testLogin(username: String, password: String) {
        self.clearCookies()
        let parameters = [
            "username": username,
            "password": password
        ]

        manager.request(.POST, loginUrl, parameters: parameters).validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let _ = response.result.value {
                    SVProgressHUD.showErrorWithStatus("Logged in".localized())
                    let keychain = KeychainWrapper.defaultKeychainWrapper()
                    keychain.setString(username, forKey: SettingsKeys.JNET_USERNAME)
                    keychain.setString(password, forKey: SettingsKeys.JNET_PASSWORD)
                } else {
                    fallthrough
                }
            default:
                SVProgressHUD.showErrorWithStatus("Login failed".localized())
                self.clearCredentials()
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: SettingsKeys.USE_JNET)
            }
        }
    }
    
    func uploadDeck(deck: Deck) {
        let keychain = KeychainWrapper.defaultKeychainWrapper()
        guard let
            username = keychain.stringForKey(SettingsKeys.JNET_USERNAME),
            password = keychain.stringForKey(SettingsKeys.JNET_PASSWORD) else {
                return
        }

        self.clearCookies()
        
        let parameters = [
            "username": username,
            "password": password
        ]
        
        manager.request(.POST, loginUrl, parameters: parameters).validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let _ = response.result.value {
                    self.postDeckData(deck, username: username)
                } else {
                    fallthrough
                }
            default:
                SVProgressHUD.showErrorWithStatus("Login failed".localized())
            }
        }
    }
    
    func postDeckData(deck: Deck, username: String) {
        let cards = NSMutableArray()
        for cc in deck.cards {
            let c = NSMutableDictionary()
            c["qty"] = cc.count
            c["card"] = cc.card.englishName
            cards.addObject(c)
        }
        
        var id = [String: AnyObject]()
        let identity = deck.identity ?? Card.null()
        
        id["title"] = Card.fullNames[identity.code] ?? identity.englishName
        id["code"] = identity.code
        id["side"] = identity.role == .Runner ? "Runner" : "Corp"
        id["influencelimit"] = identity.influenceLimit
        id["minimumdecksize"] = identity.minimumDecksize
        if identity.role == .Runner {
            id["baselink"] = identity.baseLink
        }
        id["faction"] = Faction.fullName(identity.faction)
        
        let fmt = NSDateFormatter()
        fmt.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        fmt.timeZone = NSTimeZone(abbreviation: "UTC")
        // 2016-07-19T06:05:52.404Z
        let date = fmt.stringFromDate(deck.lastModified ?? NSDate())
        
        let parameters: [String: AnyObject] = [
            "name": deck.name ?? "",
            "cards": cards,
            "identity": id,
            "date": date,
            "username": username
        ]
        
        manager.request(.POST, deckUrl, parameters: parameters, encoding: .JSON).validate().responseJSON { response in
            switch response.result {
            case .Success:
                SVProgressHUD.showSuccessWithStatus("Deck uploaded".localized())
                break
            default:
                SVProgressHUD.showErrorWithStatus("Upload failed".localized())
                break
            }
        }
    }
}
