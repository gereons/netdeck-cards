//
//  Answers.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Crashlytics

class Analytics: NSObject {
    
    class func logEvent(name: String, attributes: [String: AnyObject]?) {
        if BuildConfig.useCrashlytics {
            Answers.logCustomEventWithName(name, customAttributes: attributes)
        }
    }
}