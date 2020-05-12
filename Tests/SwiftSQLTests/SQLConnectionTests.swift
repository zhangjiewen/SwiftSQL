// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import SwiftSQL

final class SQLConnectionTests: XCTestCase {
    var tempDir: TempDirectory!

    override func setUp() {
        super.setUp()

        tempDir = try! TempDirectory()
    }

    override func tearDown() {
        super.tearDown()

        try! tempDir.destroy()
    }

    // MARK: Opening Connection

    func testInit() {
        // WHEN/THEN
        XCTAssertNoThrow(try SQLConnection(url: tempDir.file(named: "temp-db")))
    }

    func testInitTemporary() {
        // WHEN/THEN
        XCTAssertNoThrow(try SQLConnection(location: .temporary))
    }

    func testInitInMemoryPrivate() {
        // WHEN/THEN
        XCTAssertNoThrow(try SQLConnection(location: .memory()))
    }

    func testInitInMemoryNamed() {
        // WHEN/THEN
        XCTAssertNoThrow(try SQLConnection(location: .memory(name: "temp")))
    }
}
