// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import SwiftSQL

final class SQLDataTypeTests: XCTestCase {
    var db: SQLConnection!

    override func setUp() {
        super.setUp()

        db = try! SQLConnection(location: .memory())
    }

    func testInt32() throws {
        try db.execute("CREATE TABLE Test (Field INTEGER)")

        // WHEN/THEN binds the value
        try db.statement("INSERT INTO Test (Field) VALUES (?)")
            .bind(Int32.max)
            .execute()

        // WHEN/THEN reads the value
        let row = try XCTUnwrap(db.statement("SELECT Field FROM Test").next())
        XCTAssertEqual(row[0], Int32.max)
    }

    func testInt64() throws {
        try db.execute("CREATE TABLE Test (Field INTEGER)")

        // WHEN/THEN binds the value
        try db.statement("INSERT INTO Test (Field) VALUES (?)")
            .bind(Int64.max)
            .execute()

        // WHEN/THEN reads the value
        let row = try XCTUnwrap(db.statement("SELECT Field FROM Test").next())
        XCTAssertEqual(row[0], Int64.max)
    }

    func testString() throws {
        try db.execute("CREATE TABLE Test (Field VARCHAR)")

        // WHEN/THEN binds the value
        try db.statement("INSERT INTO Test (Field) VALUES (?)")
            .bind("Test")
            .execute()

        // WHEN/THEN reads the value
        let row = try XCTUnwrap(db.statement("SELECT Field FROM Test").next())
        XCTAssertEqual(row[0], "Test")
    }

    func testDouble() throws {
        try db.execute("CREATE TABLE Test (Field REAL)")

        // WHEN/THEN binds the value
        try db.statement("INSERT INTO Test (Field) VALUES (?)")
            .bind(10.5)
            .execute()

        // WHEN/THEN reads the value
        let row = try XCTUnwrap(db.statement("SELECT Field FROM Test").next())
        XCTAssertEqual(row[0], 10.5)
    }

    func testNilString() throws {
        try db.execute("CREATE TABLE Test (Field VARCHAR)")

        // WHEN/THEN binds the value
        try db.statement("INSERT INTO Test (Field) VALUES (?)")
            .bind(nil)
            .execute()

        // WHEN/THEN reads the value
        let row = try XCTUnwrap(db.statement("SELECT Field FROM Test").next())
        XCTAssertEqual(row[0] as String?, nil)
    }

    func testNilInt() throws {
        try db.execute("CREATE TABLE Test (Field INTEGER)")

        // WHEN/THEN binds the value
        try db.statement("INSERT INTO Test (Field) VALUES (?)")
            .bind(nil)
            .execute()

        // WHEN/THEN reads the value
        let row = try XCTUnwrap(db.statement("SELECT Field FROM Test").next())
        XCTAssertEqual(row[0] as Int32?, nil)
    }
}
