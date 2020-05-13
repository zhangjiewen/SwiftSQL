// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import SwiftSQL
import SwiftSQLExt

final class SwiftSQLExtTests: XCTestCase {
    var tempDir: TempDirectory!
    var db: SQLConnection!

    override func setUp() {
        super.setUp()

        tempDir = try! TempDirectory()
        db = try! SQLConnection(location: .disk(url: tempDir.file(named: "test-statements")))
    }

    override func tearDown() {
        super.tearDown()

        try! tempDir.destroy()
    }

    // MARK: Rows

    func testRow() throws {
        // GIVEN
        try db.populateStore()

        // WHEN
        let user = try db
            .prepare("SELECT Name, Level FROM Users ORDER BY Level ASC")
            .row(User.self)

        // THEN
        XCTAssertEqual(user, User(name: "Alice", level: 80))
    }

    func testRows() throws {
        // GIVEN
        try db.populateStore()

        // WHEN
        let users = try db
            .prepare("SELECT Name, Level FROM Users ORDER BY Level ASC")
            .rows(User.self)

        // THEN
        XCTAssertEqual(users, [
            User(name: "Alice", level: 80),
            User(name: "Bob", level: 90)
        ])
    }

    func testFirstNRows() throws {
        // GIVEN
        try db.populateStore()

        // WHEN
        let users = try db
            .prepare("SELECT Name, Level FROM Users ORDER BY Level ASC")
            .rows(count: 1, User.self)

        // THEN
        XCTAssertEqual(users, [
            User(name: "Alice", level: 80)
        ])
    }
}

private extension SQLConnection {
    func populateStore() throws {
        try execute("""
        CREATE TABLE Users
        (
            Id INTEGER PRIMARY KEY NOT NULL,
            Name VARCHAR,
            Level INTEGER
        )
        """)

        let statement = try self.prepare("""
        INSERT INTO Users (Name, Level)
        VALUES (?, ?)
        """)

        try statement
            .bind("Alice", Int64(80))
            .execute()

        try statement.reset()

        try statement
            .bind("Bob", Int64(90))
            .execute()
    }
}


private struct User: Hashable, SQLRowDecodable {
    let name: String
    let level: Int64

    init(name: String, level: Int64) {
        self.name = name
        self.level = level
    }

    init(row: SQLRow) throws {
        self.name = row[0]
        self.level = row[1]
    }
}
