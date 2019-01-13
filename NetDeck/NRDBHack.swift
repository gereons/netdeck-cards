//
//  NRDBHack.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.03.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import Alamofire
import SwiftKeychainWrapper
import SVProgressHUD
import SwiftyUserDefaults

class NRDBHack {

    private static let authUrl = NRDB.providerHost + "/oauth/v2/auth"
    private static let loginCheckUrl = NRDB.providerHost + "/oauth/v2/auth_login_check"
    
    private let cookieJar = HTTPCookieStorage.shared
    private let manager: Alamofire.SessionManager
    private var authCompletion: ((Bool, String) -> Void)!
    
    static let sharedInstance = NRDBHack()

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = self.cookieJar
        cfg.httpShouldSetCookies = true
        self.manager = Alamofire.SessionManager(configuration: cfg)
    }
    
    private(set) var loggingIn = false
    
    private struct Credentials {
        let username: String
        let password: String
        
        init(_ username: String, _ password: String) {
            self.username = username
            self.password = password
        }

        static func fromKeychain() -> Credentials? {
            let keychain = KeychainWrapper.standard
            if let username = keychain.string(forKey: KeychainKeys.nrdbUsername), let password = keychain.string(forKey: KeychainKeys.nrdbPassword) {
                return Credentials(username, password)
            }
            return nil
        }
    }
    
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
        
        alert.addAction(UIAlertAction(title: "Login".localized(), style: .default) { [unowned self] action in
            let username = alert.textFields?[0].text ?? ""
            let password = alert.textFields?[1].text ?? ""
            let credentials = Credentials(username, password)
            self.hackedLogin(credentials) { success, error in
                self.loginCompleted(success, error, verbose: true, credentials: credentials)
            }
            SVProgressHUD.show(withStatus: "Logging in...".localized())
        })
            
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel) { action in
            Defaults[.useNrdb] = false
            Defaults[.nrdbLoggedin] = false
        })
        
        alert.show()
    }
    
    func silentlyLoginOnStartup() {
        let expiry = Defaults[.nrdbTokenExpiry] ?? Date()
        let now = Date()
        let diff = expiry.timeIntervalSince(now) - NRDB.fiveMinutes
        
        if diff < 0 {
            self.silentlyLogin()
        }
    }
    
    func silentlyLogin() {
        if let credentials = Credentials.fromKeychain() {
            // print("silent login attempt")
            self.hackedLogin(credentials) { success, error in
                self.loginCompleted(success, error, verbose: false, credentials: credentials)
            }
        }
    }
    
    private func loginCompleted(_ success: Bool, _ error: String, verbose: Bool, credentials: Credentials) {
        print("nrdb login completed ok=\(success) verbose=\(verbose) error=\(error)")
        self.loggingIn = false
        Defaults[.nrdbLoggedin] = success
        if success {
            if verbose {
                SVProgressHUD.dismiss()
            }
            let keychain = KeychainWrapper.standard
            keychain.set(credentials.username, forKey: KeychainKeys.nrdbUsername)
            keychain.set(credentials.password, forKey: KeychainKeys.nrdbPassword)
            
            NRDB.sharedInstance.startAuthorizationRefresh()

        } else {
            if verbose {
                SVProgressHUD.showError(withStatus: "Login failed".localized())
            }
        }
    }
        
    static func clearCredentials() {
        let keychain = KeychainWrapper.standard
        keychain.removeObject(forKey: KeychainKeys.nrdbUsername)
        keychain.removeObject(forKey: KeychainKeys.nrdbPassword)
    }
    
    private func hackedLogin(_ credentials: Credentials, _ completion: @escaping (Bool, String) -> Void) {
        // print("hacking around oauth login")
        self.loggingIn = true
        
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
        
        self.manager.delegate.taskWillPerformHTTPRedirection = self.redirectHandler
        
        let parameters = [
            "client_id": NRDB.clientId,
            "response_type": "code",
            "redirect_uri": NRDB.clientHost
        ]

        self.manager.request(NRDBHack.authUrl, parameters: parameters).validate().responseString { response in
            let parameters = [
                "_username": credentials.username,
                "_password": credentials.password,
                "_submit": "Log In"
            ]
            self.manager.request(NRDBHack.loginCheckUrl, method: .post, parameters: parameters).validate().responseString { response in
                if let body = response.result.value, let token = self.findToken(body) {
                    let accept = [
                        "accepted": "Allow",
                        "fos_oauth_server_authorize_form[client_id]": NRDB.clientId,
                        "fos_oauth_server_authorize_form[response_type]": "code",
                        "fos_oauth_server_authorize_form[redirect_uri]": NRDB.clientHost,
                        "fos_oauth_server_authorize_form[state]": "",
                        "fos_oauth_server_authorize_form[scope]": "",
                        "fos_oauth_server_authorize_form[_token]": token
                    ]
                    self.manager
                        .request(NRDBHack.authUrl, method: .post, parameters: accept)
                        .responseString { response in
                            if response.result.value != nil {
                                completion(false, "oops")
                            }
                    }
                } else {
                    completion(false, "no token found")
                }
            }
        }
    }
    
    private func redirectHandler(_ session: URLSession, task: URLSessionTask, response: HTTPURLResponse, request: URLRequest) -> URLRequest? {
        // print("nrdb hack: redirecting to \(request.url)")
        
        if let url = request.url?.absoluteString, url.hasPrefix(NRDB.clientHost) {
            // this is the oauth answer we want to intercept.
            // extract the value of the "code" parameter from the URL and use that to finalize the authorization
            if let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false), let items = components.queryItems {
                if let item = items.filter({ $0.name == "code" }).first {
                    let code = item.value ?? ""
                    // print("found code \(code)")
                    NRDB.sharedInstance.authorizeWithCode(code, completion: self.authCompletion)
                }
            }
        }
        return request
    }

    private func findToken(_ body: String) -> String? {
        
        let regex = try! NSRegularExpression(pattern: "id=\"fos_oauth_server_authorize_form__token\".*value=\"(.*)\"", options:[])
        
        let line = body
        if let match = regex.firstMatch(in: line, options: [], range: NSMakeRange(0, line.count)) {
            if match.numberOfRanges == 2 {
                let l = line as NSString
                let token = l.substring(with: match.range(at: 1))
                return token
            }
        }
        return nil
    }
    
}
