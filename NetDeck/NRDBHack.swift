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
    
    private var cookieJar = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    private var manager: Alamofire.Manager!
    private var authCompletion: ((Bool) -> Void)!
    
    private var username: String?
    private var password: String?
    
    static let sharedInstance = NRDBHack()
    
    func enterNrdbCredentialsAndLogin() {
        let alert = UIAlertController(title: "NetrunnerDB.com Login".localized(), message: nil, preferredStyle: .Alert)
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
            self.username = alert.textFields?[0].text
            self.password = alert.textFields?[1].text!
            self.hackedLogin(self.manualLoginCompletion)
            SVProgressHUD.showWithStatus("Logging in...".localized())
        })
            
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .Cancel, handler: nil))
        
        alert.show()
    }
    
    func silentlyLogin() {
        if let username = KeychainWrapper.stringForKey(SettingsKeys.NRDB_USERNAME), password = KeychainWrapper.stringForKey(SettingsKeys.NRDB_PASSWORD) {
            self.username = username
            self.password = password
            self.hackedLogin(self.silentLoginCompletion)
        }
    }
    
    func manualLoginCompletion(ok: Bool) {
        self.loginCompletion(ok, verbose: true)
    }
    
    func silentLoginCompletion(ok: Bool) {
        self.loginCompletion(ok, verbose: false)
    }
    
    func loginCompletion(ok: Bool, verbose: Bool) {
        // NSLog("manual login completed ok=\(ok)")
        if ok {
            if verbose {
                SVProgressHUD.dismiss()
            }
            KeychainWrapper.setString(self.username!, forKey: SettingsKeys.NRDB_USERNAME)
            KeychainWrapper.setString(self.password!, forKey: SettingsKeys.NRDB_PASSWORD)
            
            NRDB.sharedInstance.startAuthorizationRefresh()
        } else {
            if verbose {
                SVProgressHUD.showErrorWithStatus("Login failed".localized())
            }
            NRDBHack.clearCredentials()
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: SettingsKeys.USE_NRDB)
        }
    }
        
    class func clearCredentials() {
        KeychainWrapper.removeObjectForKey(SettingsKeys.NRDB_USERNAME)
        KeychainWrapper.removeObjectForKey(SettingsKeys.NRDB_PASSWORD)
    }

    func hackedLogin(completion: (Bool) -> Void) {
        // NSLog("hacking around oauth login")
        
        guard let username = username, password = password else {
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
        
        let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
        cfg.HTTPCookieStorage = self.cookieJar
        cfg.HTTPShouldSetCookies = true
        self.manager = Alamofire.Manager(configuration: cfg)
        
        self.manager.delegate.taskWillPerformHTTPRedirection = self.redirectHandler
        
        let parameters = [
            "client_id": NRDB.CLIENT_ID,
            "response_type": "code",
            "redirect_uri": NRDB.CLIENT_HOST
        ]
        self.manager.request(.GET, NRDBHack.AUTH_URL, parameters: parameters).validate().responseString { response in
        
            let parameters = [
                "_username": username,
                "_password": password,
                "_submit": "Log In"
            ]
            self.manager.request(.POST, NRDBHack.CHECK_URL, parameters: parameters).validate().responseString { response in
                
                if let body = response.result.value, token = self.findToken(body) {
                    
                    let accept = [
                        "accepted": "Allow",
                        "fos_oauth_server_authorize_form[client_id]": NRDB.CLIENT_ID,
                        "fos_oauth_server_authorize_form[response_type]": "code",
                        "fos_oauth_server_authorize_form[redirect_uri]": NRDB.CLIENT_HOST,
                        "fos_oauth_server_authorize_form[state]": "",
                        "fos_oauth_server_authorize_form[scope]": "",
                        "fos_oauth_server_authorize_form[_token]": token
                    ]
                    self.manager.request(.POST, NRDBHack.AUTH_URL, parameters: accept).responseString { response in
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
    
    private func redirectHandler(session: NSURLSession!, task: NSURLSessionTask!, response: NSHTTPURLResponse!, request: NSURLRequest!) -> NSURLRequest {
        // NSLog("redirecting to \(request.URL)")
        
        if let url = request.URL?.absoluteString where url.hasPrefix(NRDB.CLIENT_HOST) {
            // this is the oauth answer we want to intercept.
            // extract the value of the "code" parameter from the URL and use that to finalize the authorization
            if let components = NSURLComponents(URL: request.URL!, resolvingAgainstBaseURL: false), items = components.queryItems {
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

    
    private func findToken(body: String) -> String? {
        
        let regex = try! NSRegularExpression(pattern: "id=\"fos_oauth_server_authorize_form__token\".*value=\"(.*)\"", options:[])
        
        let line = body
        if let match = regex.firstMatchInString(line, options: [], range: NSMakeRange(0, line.length)) {
            if match.numberOfRanges == 2 {
                let l = line as NSString
                let token = l.substringWithRange(match.rangeAtIndex(1))
                return token
            }
        }
        return nil
    }
    
}
