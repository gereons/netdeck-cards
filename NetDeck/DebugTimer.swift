//
//  DebugTimer.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.05.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation


final class DebugTimer {
   
    private struct Timer {
        var count = 0
        var time = 0.0
    }
    
    private static var timers = [String: Timer]()
    private var name = ""
    private var start: TimeInterval = 0.0
    
    init(named name: String) {
        self.name = name
        self.start = Date.timeIntervalSinceReferenceDate
    }
    
    @discardableResult
    func elapsed(verbose: Bool = false) -> TimeInterval {
        let now = Date.timeIntervalSinceReferenceDate
        let elapsed = now - self.start
        if verbose {
            print("- \(self.name): \(elapsed)s")
        }
        return elapsed
    }
    
    @discardableResult
    func elapsed(_ str: String) -> TimeInterval {
        let now = Date.timeIntervalSinceReferenceDate
        let elapsed = now - self.start
        print("- \(self.name): \(str) \(elapsed)s")
        return elapsed
    }
    
    func stop(verbose: Bool = false) {
        let elapsed = self.elapsed()
        
        if var t = DebugTimer.timers[self.name] {
            t.count += 1
            t.time += elapsed
            DebugTimer.timers[self.name] = t
        } else {
            DebugTimer.timers[self.name] = Timer(count: 1, time: elapsed)
        }
        if verbose {
            print("stopped \(self.name) after \(elapsed)s")
        }
    }
    
    static func printAll() {
        for (key, value) in DebugTimer.timers {
            let avg = value.time / Double(value.count)
            NSLog("\(key): \(value.count) \(value.time) \(avg)")
        }
    }
    
    static func reset(_ names: [String]? = nil) {
        if let names = names {
            for n in names {
                self.timers.removeValue(forKey: n)
            }
        } else {
            self.timers.removeAll()
        }
    }

}

final class SimpleTimer {
    let start: TimeInterval
    let str: String
    
    init(_ str: String) {
        self.start = Date.timeIntervalSinceReferenceDate
        self.str = str
    }
    
    func stop() {
        let elapsed = Date.timeIntervalSinceReferenceDate - start
        print("\(str) took \(elapsed)s")
    }
}
