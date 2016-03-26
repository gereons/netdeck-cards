//
//  Answers.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

import Crashlytics

class Analytics: NSObject {
    static var enableAnswers = false
    
    class func logEvent(name: String, attributes: [String: AnyObject]?) {
        if enableAnswers {
            Answers.logCustomEventWithName(name, customAttributes: attributes)
        }
    }
}