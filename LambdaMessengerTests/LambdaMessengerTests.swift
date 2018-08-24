//
//  LambdaMessengerTests.swift
//  LambdaMessengerTests
//
//  Created by John Robokos on 8/7/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import XCTest
import XCGLogger

@testable import LambdaMessenger

class LambdaMessengerTests: XCTestCase {
    let log = XCGLogger.default
    
    func testValidation() {
        let util = PhoneNumberUtil();
        XCTAssertTrue(util.validate("2125551212"));
        XCTAssertTrue(util.validate("212-555-1212"));
        XCTAssertTrue(util.validate("1-212-555-1212"));
        XCTAssertEqual(util.parse("1-212-555-1212"),
                       util.parse("212-555-1212"))
        XCTAssertTrue(util.validate("+12125551212"));
        XCTAssertFalse(util.validate("+1-212-552"));
        XCTAssertFalse(util.validate(""));
        XCTAssertFalse(util.validate("asdasdasdasd"));
    }
    
}
