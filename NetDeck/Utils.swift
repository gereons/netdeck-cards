//
//  Utils.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.11.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation
import Marshal

class Utils {
    
    // utility method: set the excludeFromBackup flag on the specified path
    static func excludeFromBackup(_ path: String) {
        let url = NSURL(fileURLWithPath:path)
        do {
            try url.setResourceValue(true, forKey:URLResourceKey.isExcludedFromBackupKey)
        } catch let error {
            NSLog("setResource error=\(error)")
        }
    }

    static func appVersion() -> String {
        var version = ""
        if let bundleInfo = Bundle.main.infoDictionary {
            // CFBundleShortVersionString contains the main version
            let shortVersion = (bundleInfo["CFBundleShortVersionString"] as? String) ?? ""
            version = "v" + shortVersion

            if BuildConfig.debug {
                // CFBundleVersion contains the git rev-parse output
                let bundleVersion = (bundleInfo["CFBundleVersion"] as? String) ?? ""
                version += "-" + bundleVersion
            }
        }
        return version
    }

    static private let supportedNrdbApiVersion = "2.0"
    static func validJsonResponse(json: JSONObject) -> Bool {
        do {
            let version: String = try json.value(for: "version_number")
            let success: Bool = try json.value(for: "success")
            let total: Int = try json.value(for: "total")
            return success && version == supportedNrdbApiVersion && total > 0
        } catch {
            return false
        }
    }

}
