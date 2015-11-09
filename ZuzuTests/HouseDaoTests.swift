//
//  HouseDaoTests.swift
//  Zuzu
//
//  Created by eechih on 2015/11/9.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Zuzu
import XCTest

class HouseDaoTests: XCTestCase {

    var houseDao: HouseDao!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        houseDao = HouseDao()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssert(true, "Pass")

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
