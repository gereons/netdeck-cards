//
//  Answers.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.03.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Crashlytics

class Analytics: NSObject {
    
    class func logEvent(_ name: String, attributes: [String: Any]? = nil) {
        if BuildConfig.useCrashlytics {
            Answers.logCustomEvent(withName: name, customAttributes: attributes)
        }
    }
}
