//
//  NetDeckTests.swift
//  NetDeckTests
//
//  Created by Gereon Steffens on 13.04.18.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import XCTest


class NetDeckTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testConcurrentMap() {
        var cm = ConcurrentMap<String, String>()

        XCTAssert(cm.count == 0)
        cm["foo"] = "bar"
        XCTAssert(cm.count == 1)
        XCTAssert(cm["foo"] == "bar")

        cm.removeValue(forKey: "foo")
        XCTAssert(cm.count == 0)
        XCTAssert(cm["foo"] == nil)
    }

    func testConcurrentMap2() {
        var cm = ConcurrentMap<String, [String]>()

        XCTAssert(cm.count == 0)
        cm["foo"] = ["bar"]
        cm["foo"]?.append("baz")
        XCTAssert(cm.count == 1)
        XCTAssert(cm["foo"] == ["bar", "baz"])

        cm["bar", default:[]].append("blergh")
        XCTAssert(cm.count == 2)
        XCTAssert(cm["bar"]?.count == 1)

        cm["otto", default: ["franz"]] = ["karl"]
        XCTAssert(cm.count == 3)
        XCTAssert(cm["otto"] == ["karl"])

        XCTAssert(cm["franz", default:[]] == [])
        cm.removeValue(forKey: "otto")
        cm.removeValue(forKey: "foo")
        XCTAssert(cm.count == 1)
        XCTAssert(cm["foo"] == nil)
    }

    func testConcurrentMap3() {
        var cm = ConcurrentMap<String, [String]>()
        cm["bar", default:[]].append("blergh")
        XCTAssert(cm.count == 1)
        XCTAssert(cm["bar"]?.count == 1)
    }

}
