//
//  Reachability.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Alamofire
import AlamofireNetworkActivityIndicator

class Reachability: NSObject {
    static var manager: NetworkReachabilityManager?
    
    class func start() {
        let host = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NRDB_HOST) ?? "www.apple.com"
        Reachability.manager = NetworkReachabilityManager(host: host)
        Reachability.manager?.listener = { status in
            // print("Network Status Changed: \(status)")
            switch status {
            case .NotReachable:
                NRDB.sharedInstance.stopAuthorizationRefresh()
            default:
                NRDB.sharedInstance.startAuthorizationRefresh()
            }
        }
    
        Reachability.manager?.startListening()
        
        NetworkActivityIndicatorManager.sharedManager.isEnabled = true
        NetworkActivityIndicatorManager.sharedManager.startDelay = 0.2
    }
    
    class func online() -> Bool {
        return manager?.isReachable ?? true
    }
}