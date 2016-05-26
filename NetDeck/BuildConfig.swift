//
//  BuildConfig.swift
//  NetDeck
//
//  Created by Gereon Steffens on 16.04.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

struct BuildConfig {
    #if RELEASE
    static let release = true
    #else
    static let release = false
    #endif
    
    static let debug = !release
    
    static let debugCrashLytics = false
    
    static let useCrashlytics = release || debugCrashLytics
}

class Device: NSObject {
    static var isIphone: Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Phone
    }

    static var isIpad: Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
    
    static let screenSize = UIScreen.mainScreen().bounds.size
    static let maxSize = max(screenSize.width, screenSize.height)
    
    static var isIphone4: Bool {
        return isIphone && maxSize < 568
    }
}