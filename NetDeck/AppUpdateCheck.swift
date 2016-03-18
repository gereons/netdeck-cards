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
    
    static let WEEK: NSTimeInterval = 7*24*60*60 // one week in seconds
    
    class func checkUpdate() {
        
        let settings = NSUserDefaults.standardUserDefaults()
        
        guard let nextCheck = settings.objectForKey(SettingsKeys.NEXT_UPDATE_CHECK) as? NSDate else {
            let nextCheck = NSDate(timeIntervalSinceNow: WEEK)
            settings.setObject(nextCheck, forKey: SettingsKeys.NEXT_UPDATE_CHECK)
            return
        }
        
        let now = NSDate()
        if now.timeIntervalSince1970 > nextCheck.timeIntervalSince1970 && AppDelegate.online() {
            self.checkForUpdate { version in
                if let v = version {
                    let msg = String(format: "Version %@ is available on the App Store".localized(), v)
                    let alert = UIAlertController.alertWithTitle("Update available".localized(), message: msg)
                    
                    alert.addAction(UIAlertAction(title: "Update".localized(), style: .Cancel) { action in
                        let url = "itms-apps://itunes.apple.com/app/id865963530"
                        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
                    })
                    
                    alert.addAction(UIAlertAction(title: "Not now".localized(), style: .Default, handler: nil))

                    alert.show()
                }
            }
            
            settings.setObject(now.dateByAddingTimeInterval(WEEK), forKey: SettingsKeys.NEXT_UPDATE_CHECK)
        }
    }
    
    
    private class func checkForUpdate(completion: (String?) -> Void)  {
        guard
            let dict = NSBundle.mainBundle().infoDictionary,
            let bundleId = dict["CFBundleIdentifier"] as? String,
            let currentVersion = dict["CFBundleShortVersionString"] as? String else {
            completion(nil)
            return
        }
        
        let url = "https://itunes.apple.com/lookup?bundleId=" + bundleId
        
        Alamofire.request(.GET, url).responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    if let appstoreVersion = json["results"][0]["version"].string {
                        if let appstore = Double(appstoreVersion), let current = Double(currentVersion) {
                            completion(appstore > current ? appstoreVersion : nil)
                            return
                        }
                    }
                }
                fallthrough
            case .Failure:
                completion(nil)
            }
        }
    }
}
