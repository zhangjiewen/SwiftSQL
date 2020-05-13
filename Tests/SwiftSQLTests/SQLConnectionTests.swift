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

    // MARK: Info

    func testLastInsertRowID() throws {
        // GIVEN
        let db = try SQLConnection(location: .memory())
        try db.execute("CREATE TABLE Test (Field VARCHAR)")

        // THEN
        XCTAssertEqual(db.lastInsertRowID, 0)

        // WHEN
        try db.prepare("INSERT INTO Test (Field) VALUES (?)")
            .bind("A")
            .execute()

        // THEN
        XCTAssertEqual(db.lastInsertRowID, 1)

        // WHEN
        try db.prepare("INSERT INTO Test (Field) VALUES (?)")
             .bind("B")
             .execute()

        // THEN
        XCTAssertEqual(db.lastInsertRowID, 2)
    }
}
