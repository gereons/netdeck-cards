//
//  AppUpdateCheck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 11.03.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import Alamofire
import SwiftyUserDefaults

private struct Version: Comparable {
    private(set) var major = 0
    private(set) var minor = 0
    private(set) var patch = 0

    init(_ str: String) {
        let parts = str.components(separatedBy: ".")
        if parts.count > 0 {
            self.major = Int(parts[0]) ?? 0
        }
        if parts.count > 1 {
            self.minor = Int(parts[1]) ?? 0
        }
        if parts.count > 2 {
            self.patch = Int(parts[2]) ?? 0
        }
    }

    static func ==(_ lhs: Version, _ rhs: Version) -> Bool {
        return lhs.major == rhs.major &&
            lhs.minor == rhs.minor &&
            lhs.patch == rhs.patch
    }

    static func <(_ lhs: Version, _ rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}

private struct LookupResults: Codable {
    let results: [LookupResult]
}

private struct LookupResult: Codable {
    let version: String
}

class AppUpdateCheck {

    static let day: TimeInterval = 24 * 60 * 60
    static let week: TimeInterval = 7 * day

    static let forceTest = false
    
    static func checkUpdate() {
        guard let nextCheck = Defaults[.nextUpdateCheck] else {
            Defaults[.nextUpdateCheck] = Date(timeIntervalSinceNow: day)
            return
        }
        
        let force = forceTest && BuildConfig.debug
        let now = Date()
        let checkNow = now.timeIntervalSince1970 > nextCheck.timeIntervalSince1970
        if (checkNow && Reachability.online) || force {
            Defaults[.nextUpdateCheck] = now.addingTimeInterval(day)
            self.checkForUpdate { version in
                if let v = version {
                    let msg = String(format: "Version %@ is available on the App Store".localized(), v)
                    let alert = UIAlertController.alert(title: "Update available".localized(), message: msg)

                    alert.addAction(UIAlertAction(title: "Update".localized(), style: .cancel) { action in
                        let url = "itms-apps://itunes.apple.com/app/id865963530"
                        Analytics.logEvent(.appUpdateStarted)
                        UIApplication.shared.open(URL(string: url)!)
                    })

                    alert.addAction(UIAlertAction(title: "Not now".localized(), style: .default) { action in
                        Defaults[.nextUpdateCheck] = now.addingTimeInterval(week)
                    })

                    alert.show()

                    let dict = Bundle.main.infoDictionary
                    let currentVersion = dict?["CFBundleShortVersionString"] as? String
                    Analytics.logEvent(.appUpdateAvailable, attributes: ["currentVersion": currentVersion ?? "n/a" ])
                }
            }
        }
    }
    
    private static func checkForUpdate(_ completion: @escaping (String?) -> Void) {
        guard
            let dict = Bundle.main.infoDictionary,
            let bundleId = dict["CFBundleIdentifier"] as? String,
            let bundleVersionString = dict["CFBundleShortVersionString"] as? String
        else {
            completion(nil)
            return
        }
        
        let url = "https://itunes.apple.com/lookup?bundleId=" + bundleId
        
        Alamofire.request(url).responseJSON { response in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let lookup = try JSONDecoder().decode(LookupResults.self, from: data)

                        let appstoreVersionString = lookup.results.first?.version ?? ""
                        let appstoreVersion = Version(appstoreVersionString)
                        let bundleVersion = Version(bundleVersionString)
                        completion(appstoreVersion > bundleVersion ? appstoreVersionString : nil)
                        break
                    } catch let error {
                        print("\(error)")
                    }
                }
                fallthrough
            case .failure:
                completion(nil)
            }
        }
    }
}
