//
//  Utils.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.11.17.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import Foundation

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

}
