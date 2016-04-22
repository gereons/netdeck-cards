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
}
