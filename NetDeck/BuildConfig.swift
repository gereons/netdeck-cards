//
//  BuildConfig.swift
//  NetDeck
//
//  Created by Gereon Steffens on 16.04.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

struct BuildConfig {
    #if RELEASE
    static let release = true
    #else
    static let release = false
    #endif
    
    static let debug = !release
    
    static let debugSentry = false
    
    static let useSentry = release || debugSentry
}

final class Device {
    static var isIphone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static let screenSize = UIScreen.main.bounds.size
    static let maxSize = max(screenSize.width, screenSize.height)
    
    static var isIphone4: Bool {
        return isIphone && maxSize < 568
    }
}
