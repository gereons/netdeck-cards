//
//  NRDBHack.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Alamofire

class NRDBHack: NSObject {

    static let AUTH_URL = NRDB.PROVIDER_HOST + "/oauth/v2/auth"
    static let CHECK_URL = NRDB.PROVIDER_HOST + "/oauth/v2/auth_login_check"
    
    private var cookieJar = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    private var manager: Alamofire.Manager!
    private var completion: ((Bool) -> Void)!

    func redirectHandler(session: NSURLSession!, task: NSURLSessionTask!, response: NSHTTPURLResponse!, request: NSURLRequest!) -> NSURLRequest {
        print("redirecting to \(request.URL)")
        
        if let url = request.URL?.absoluteString where url.hasPrefix(NRDB.CLIENT_HOST) {
            // this is the oauth answer we want to intercept. 
            // extract the value of the "code" parameter from the URL and use that to finalize the authorization
            if let components = NSURLComponents(URL: request.URL!, resolvingAgainstBaseURL: false), items = components.queryItems {
                for item in items {
                    if item.name == "code"{
                        let code = item.value
                        print("found code \(code)")
                        NRDB.sharedInstance.authorizeWithCode(code ?? "", completion: completion)
                    }
                }
            }
        }
        return request
    }

    func hackedLogin(userName: String, password: String, completion: (Bool) -> Void) {
        print("hacking around oauth login")
        
        self.completion = completion
        
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
                "_username": userName,
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
                }
            }
        }
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
