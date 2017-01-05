//
//  AppUpdateCheck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 11.03.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Alamofire
import Marshal

class AppUpdateCheck: NSObject {
    
    static let week: TimeInterval = 7*24*60*60 // one week in seconds
    static let forceTest = false
    
    class func checkUpdate() {
        
        let settings = UserDefaults.standard
        
        guard let nextCheck = settings.object(forKey: SettingsKeys.NEXT_UPDATE_CHECK) as? Date else {
            let nextCheck = Date(timeIntervalSinceNow: week)
            settings.set(nextCheck, forKey: SettingsKeys.NEXT_UPDATE_CHECK)
            return
        }
        
        let force = forceTest && BuildConfig.debug
        let now = Date()
        if (now.timeIntervalSince1970 > nextCheck.timeIntervalSince1970 && Reachability.online) || force {
            self.checkForUpdate { version in
                if let v = version {
                    let msg = String(format: "Version %@ is available on the App Store".localized(), v)
                    let alert = UIAlertController.alert(title: "Update available".localized(), message: msg)
                    
                    alert.addAction(UIAlertAction(title: "Update".localized(), style: .cancel) { action in
                        let url = "itms-apps://itunes.apple.com/app/id865963530"
                        UIApplication.shared.openURL(URL(string: url)!)
                    })
                    
                    alert.addAction(UIAlertAction(title: "Not now".localized(), style: .default, handler: nil))

                    alert.show()
                }
            }
            
            settings.set(now.addingTimeInterval(week), forKey: SettingsKeys.NEXT_UPDATE_CHECK)
        }
    }
    
    private struct AppStoreResult: Unmarshaling {
        let version: String
        
        init(object: MarshaledObject) throws {
            self.version = try object.value(for: "version")
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
                if let data = response.data {
                    do {
                        let json = try JSONParser.JSONObjectWithData(data)
                        
                        let results: [AppStoreResult] = try json.value(for: "results")
                        if let appstoreVersion = results.first?.version {
                            let cmp = appstoreVersion.compare(currentVersion, options: .numeric)
                            completion(cmp == .orderedDescending ? appstoreVersion : nil)
                        }
                    } catch {}
                }
                fallthrough
            case .failure:
                completion(nil)
            }
        }
    }
}
