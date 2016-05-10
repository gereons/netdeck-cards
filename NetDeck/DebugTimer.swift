//
//  DebugTimer.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.05.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class DebugTimer: NSObject {
   
    struct Timer {
        var count = 0
        var time = 0.0
    }
    static var timers = [String: Timer]()
    var name = ""
    var start: NSTimeInterval = 0.0
    
    init(name: String) {
        self.name = name
        self.start = NSDate().timeIntervalSinceReferenceDate
    }
    
    func stop() {
        let now = NSDate().timeIntervalSinceReferenceDate
        let elapsed = now - self.start
        
        if var t = DebugTimer.timers[name] {
            t.count += 1
            t.time += elapsed
            DebugTimer.timers[name] = t
        } else {
            DebugTimer.timers[name] = Timer(count: 1, time: elapsed)
        }
    }
    
    static func print() {
        for (key, value) in DebugTimer.timers {
            let avg = value.time / Double(value.count)
            NSLog("\(key): \(value.count) \(value.time) \(avg)")
        }
    }
    static func reset() {
        self.timers.removeAll()
    }
}