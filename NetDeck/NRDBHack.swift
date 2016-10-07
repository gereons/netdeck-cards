//
//  NRDBHack.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Alamofire
import SwiftKeychainWrapper
import SVProgressHUD

class NRDBHack: NSObject {

    static let AUTH_URL = NRDB.PROVIDER_HOST + "/oauth/v2/auth"
    static let CHECK_URL = NRDB.PROVIDER_HOST + "/oauth/v2/auth_login_check"
    
    fileprivate var cookieJar = HTTPCookieStorage.shared
    fileprivate var manager: Alamofire.SessionManager!
    fileprivate var authCompletion: ((Bool) -> Void)!
    
    fileprivate var username: String?
    fileprivate var password: String?
    
    static let sharedInstance = NRDBHack()
    
    func enterNrdbCredentialsAndLogin() {
        let alert = UIAlertController(title: "NetrunnerDB.com Login".localized(), message: nil, preferredStyle: .alert)
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
        
        alert.addAction(UIAlertAction(title: "Login".localized(), style: .default) { action in
            self.username = alert.textFields?[0].text
            self.password = alert.textFields?[1].text
            self.hackedLogin(self.manualLoginCompletion)
            SVProgressHUD.show(withStatus: "Logging in...".localized())
        })
            
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        alert.show()
    }
    
    func silentlyLoginOnStartup() {
        let settings = UserDefaults.standard
        
        let expiry = settings.object(forKey: SettingsKeys.NRDB_TOKEN_EXPIRY) as? Date ?? Date()
        let now = Date()
        let diff = expiry.timeIntervalSince(now) - NRDB.FIVE_MINUTES
        
        if diff < 0 {
            self.silentlyLogin()
        }
    }
    
    func silentlyLogin() {
        let keychain = KeychainWrapper.standard
        if let username = keychain.string(forKey: SettingsKeys.NRDB_USERNAME), let password = keychain.string(forKey: SettingsKeys.NRDB_PASSWORD) {
            self.username = username
            self.password = password
            self.hackedLogin(self.silentLoginCompletion)
        }
    }
    
    func manualLoginCompletion(_ ok: Bool) {
        self.loginCompletion(ok, verbose: true)
    }
    
    func silentLoginCompletion(_ ok: Bool) {
        self.loginCompletion(ok, verbose: false)
    }
    
    func loginCompletion(_ ok: Bool, verbose: Bool) {
        // NSLog("manual login completed ok=\(ok)")
        if ok {
            if verbose {
                SVProgressHUD.dismiss()
            }
            let keychain = KeychainWrapper.standard
            keychain.set(self.username!, forKey: SettingsKeys.NRDB_USERNAME)
            keychain.set(self.password!, forKey: SettingsKeys.NRDB_PASSWORD)
            
            NRDB.sharedInstance.startAuthorizationRefresh()
        } else {
            if verbose {
                SVProgressHUD.showError(withStatus: "Login failed".localized())
            }
            NRDBHack.clearCredentials()
            UserDefaults.standard.set(false, forKey: SettingsKeys.USE_NRDB)
        }
    }
        
    class func clearCredentials() {
        let keychain = KeychainWrapper.standard
        keychain.removeObject(forKey: SettingsKeys.NRDB_USERNAME)
        keychain.removeObject(forKey: SettingsKeys.NRDB_PASSWORD)
    }

    func hackedLogin(_ completion: @escaping (Bool) -> Void) {
        // NSLog("hacking around oauth login")
        
        guard let username = username, let password = password else {
            completion(false)
            return
        }
        
        self.authCompletion = completion
        
        // make sure we're not reusing an old session
        if let cookies = self.cookieJar.cookies {
            for cookie in cookies {
                if cookie.name == "PHPSESSID" {
                    self.cookieJar.deleteCookie(cookie)
                    break
                }
            }
        }
        
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = self.cookieJar
        cfg.httpShouldSetCookies = true
        self.manager = Alamofire.SessionManager(configuration: cfg)
        
        self.manager.delegate.taskWillPerformHTTPRedirection = self.redirectHandler
        
        let parameters = [
            "client_id": NRDB.CLIENT_ID,
            "response_type": "code",
            "redirect_uri": NRDB.CLIENT_HOST
        ]
        self.manager.request(NRDBHack.AUTH_URL, parameters: parameters).validate().responseString { response in
        
            let parameters = [
                "_username": username,
                "_password": password,
                "_submit": "Log In"
            ]
            self.manager.request(NRDBHack.CHECK_URL, method: .post, parameters: parameters).validate().responseString { response in
                
                if let body = response.result.value, let token = self.findToken(body) {
                    
                    let accept = [
                        "accepted": "Allow",
                        "fos_oauth_server_authorize_form[client_id]": NRDB.CLIENT_ID,
                        "fos_oauth_server_authorize_form[response_type]": "code",
                        "fos_oauth_server_authorize_form[redirect_uri]": NRDB.CLIENT_HOST,
                        "fos_oauth_server_authorize_form[state]": "",
                        "fos_oauth_server_authorize_form[scope]": "",
                        "fos_oauth_server_authorize_form[_token]": token
                    ]
                    self.manager.request(NRDBHack.AUTH_URL, method: .post, parameters: accept).responseString { response in
                        if response.result.value != nil {
                            completion(false)
                        }
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
    
    fileprivate func redirectHandler(_ session: URLSession!, task: URLSessionTask!, response: HTTPURLResponse!, request: URLRequest!) -> URLRequest {
        // NSLog("redirecting to \(request.URL)")
        
        if let url = request.url?.absoluteString , url.hasPrefix(NRDB.CLIENT_HOST) {
            // this is the oauth answer we want to intercept.
            // extract the value of the "code" parameter from the URL and use that to finalize the authorization
            if let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false), let items = components.queryItems {
                for item in items {
                    if item.name == "code"{
                        let code = item.value
                        // NSLog("found code \(code)")
                        NRDB.sharedInstance.authorizeWithCode(code ?? "", completion: self.authCompletion)
                    }
                }
            }
        }
        return request
    }

    
    fileprivate func findToken(_ body: String) -> String? {
        
        let regex = try! NSRegularExpression(pattern: "id=\"fos_oauth_server_authorize_form__token\".*value=\"(.*)\"", options:[])
        
        let line = body
        if let match = regex.firstMatch(in: line, options: [], range: NSMakeRange(0, line.length)) {
            if match.numberOfRanges == 2 {
                let l = line as NSString
                let token = l.substring(with: match.rangeAt(1))
                return token
            }
        }
        return nil
    }
    
}
