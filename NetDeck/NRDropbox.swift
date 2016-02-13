//
//  NRDropbox.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

// obj-c callable interface to the new swift-based dropbox API

import SwiftyDropbox

class NRDropbox: NSObject {
    
    class func setup() {
        Dropbox.setupWithAppKey("4mhw6piwd9wqti3")
    }

    class func handleURL(url: NSURL) -> Bool {
        if let authResult = Dropbox.handleRedirectURL(url) {
            switch authResult {
            case .Success:
                print("Success! User is logged into Dropbox.")
                return true
            case .Error(let error, let description):
                print("Error: \(error) \(description)")
                return false
            }
        }
        
        return false
    }
    
    class func authorizeFromController(controller: UIViewController) {
        if (Dropbox.authorizedClient == nil) {
            Dropbox.authorizeFromController(controller)
        } else {
            print("User is already authorized!")
        }
    }
    
    class func unlinkClient() {
        Dropbox.unlinkClient()
    }
}
