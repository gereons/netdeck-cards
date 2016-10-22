//
//  AppUpdateCheck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 11.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class AppUpdateCheck: NSObject {
    
    static let WEEK: TimeInterval = 7*24*60*60 // one week in seconds
    static let forceTest = false
    
    class func checkUpdate() {
        
        let settings = UserDefaults.standard
        
        guard let nextCheck = settings.object(forKey: SettingsKeys.NEXT_UPDATE_CHECK) as? Date else {
            let nextCheck = Date(timeIntervalSinceNow: WEEK)
            settings.set(nextCheck, forKey: SettingsKeys.NEXT_UPDATE_CHECK)
            return
        }
        
        let force = forceTest && BuildConfig.debug
        let now = Date()
        if (now.timeIntervalSince1970 > nextCheck.timeIntervalSince1970 && Reachability.online) || force {
            self.checkForUpdate { version in
                if let v = version {
                    let msg = String(format: "Version %@ is available on the App Store".localized(), v)
                    let alert = UIAlertController.alert(withTitle: "Update available".localized(), message: msg)
                    
                    alert.addAction(UIAlertAction(title: "Update".localized(), style: .cancel) { action in
                        let url = "itms-apps://itunes.apple.com/app/id865963530"
                        UIApplication.shared.openURL(URL(string: url)!)
                    })
                    
                    alert.addAction(UIAlertAction(title: "Not now".localized(), style: .default, handler: nil))

                    alert.show()
                }
            }
            
            settings.set(now.addingTimeInterval(WEEK), forKey: SettingsKeys.NEXT_UPDATE_CHECK)
        }
    }
    
    
    private class func checkForUpdate(_ completion: @escaping (String?) -> Void)  {
        guard
            let dict = Bundle.main.infoDictionary,
            let bundleId = dict["CFBundleIdentifier"] as? String,
            let currentVersion = dict["CFBundleShortVersionString"] as? String else {
            completion(nil)
            return
        }
        
        let url = "https://itunes.apple.com/lookup?bundleId=" + bundleId
        
        Alamofire.request(url).responseJSON { response in
            switch response.result {
            case .success:
                if let value = response.result.value {
                    let json = JSON(value)
                    if let appstoreVersion = json["results"][0]["version"].string {
                        let cmp = appstoreVersion.compare(currentVersion, options: .numeric)
                        completion(cmp == .orderedDescending ? appstoreVersion : nil)
                    }
                }
                fallthrough
            case .failure:
                completion(nil)
            }
        }
    }
}
