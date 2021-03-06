//
//  ThreadsafeCollections.swift
//  NetDeck
//
//  Created by Gereon Steffens on 12.04.18.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

public struct ConcurrentMap<K: Hashable, V> {
    private var map = [K: V]()
    private var queue: DispatchQueue

    public init() {
        let uuid = UUID().uuidString
        queue = DispatchQueue(label: "ConcurrentMap.\(uuid)", attributes: .concurrent)
    }

    subscript(_ key: K) -> V? {
        get {
            return queue.sync { return map[key] }
        }
        set {
            queue.sync(flags: .barrier) { map[key] = newValue }
        }
    }

    subscript(key: K, default defaultValue: @autoclosure () -> V) -> V {
        get {
            return queue.sync { return map[key, default: defaultValue()] }
        }
        set {
            queue.sync(flags: .barrier) { map[key] = newValue }
        }
    }

    mutating func removeAll() {
        queue.sync(flags: .barrier) { map.removeAll() }
    }

    @discardableResult
    mutating func removeValue(forKey key: K) -> V? {
        return queue.sync(flags: .barrier) { map.removeValue(forKey: key) }
    }

    mutating func set(_ dict: [K: V]) {
        queue.sync(flags: .barrier) { map = dict }
    }

    var dict: [K: V] {
        return queue.sync { return map }
    }

    var count: Int {
        return queue.sync { return map.count }
    }
}

struct ConcurrentSet<V: Hashable> {
    private var set = Set<V>()
    private var queue: DispatchQueue

    init() {
        let uuid = UUID().uuidString
        queue = DispatchQueue(label: "ConcurrentSet.\(uuid)", attributes: .concurrent)
    }


    mutating func insert(_ value: V) {
        queue.sync(flags: .barrier) { _ = set.insert(value) }
    }

    mutating func remove(_ value: V) {
        queue.sync(flags: .barrier) { _ = set.remove(value) }
    }

    func contains(_ value: V) -> Bool {
        return queue.sync { set.contains(value) }
    }

    mutating func removeAll() {
        queue.sync(flags: .barrier) { set.removeAll() }
    }

    mutating func formUnion(_ other: [V]) {
        queue.sync(flags: .barrier) { set.formUnion(other) }
    }

    var array: [V] {
        return queue.sync { return Array(set) }
    }
}
