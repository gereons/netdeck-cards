//
//  DebugTimer.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.05.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation


class DebugTimer: NSObject {
   
    private struct Timer {
        var count = 0
        var time = 0.0
    }
    
    private static var timers = [String: Timer]()
    private var name = ""
    private var start: TimeInterval = 0.0
    
    init(name: String) {
        self.name = name
        self.start = Date().timeIntervalSinceReferenceDate
    }
    
    func stop() {
        let now = Date().timeIntervalSinceReferenceDate
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
    
    static func reset(_ names: [String]? = nil) {
        if names == nil {
            self.timers.removeAll()
        } else {
            for n in names! {
                self.timers.removeValue(forKey: n)
            }
        }
    }

}
