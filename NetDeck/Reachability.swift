//
//  Reachability.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.03.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Alamofire
import AlamofireNetworkActivityIndicator
import SwiftyUserDefaults

class Reachability {
    static var manager: NetworkReachabilityManager?
    
    static func start() {
        let nrdbHost = Defaults[.nrdbHost]
        let host = nrdbHost.count > 0 ? nrdbHost : "www.apple.com"
        Reachability.manager = NetworkReachabilityManager(host: host)
        Reachability.manager?.listener = { status in
            print("Network Status Changed: \(status)")
            switch status {
            case .notReachable:
                NRDB.sharedInstance.stopAuthorizationRefresh()
            default:
                if Defaults[.useNrdb] {
                    if Defaults[.keepNrdbCredentials] {
                        NRDBHack.sharedInstance.silentlyLoginOnStartup()
                    } else {
                        NRDB.sharedInstance.startAuthorizationRefresh()
                    }
                }
            }
        }
    
        Reachability.manager?.startListening()
        
        NetworkActivityIndicatorManager.shared.isEnabled = true
        NetworkActivityIndicatorManager.shared.startDelay = 0.2
    }
    
    static var online: Bool {
        return manager?.isReachable ?? true
    }

}
