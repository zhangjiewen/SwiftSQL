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
            .rows(User.self, count: 1)

        // THEN
        XCTAssertEqual(users, [
            User(name: "Alice", level: 80)
        ])
    }
    
    func testIndependentSQLRows() throws {
        // GIVEN
        try db.populateStore()

        // WHEN
        let names: [String] = try db
            .prepare("SELECT Name FROM Persons ORDER BY Level ASC")
            .rows()
            .map({ $0["Name"] })

        // THEN
        XCTAssertEqual(names, [
            "Alice",
            "Bob"
        ])
    }
    
    func testIndependentSingleSQLRowNonNil() throws {
        // GIVEN
        try db.populateStore()

        // WHEN
        let row = try db
            .prepare("SELECT Name FROM Persons ORDER BY Level ASC")
            .row()

        // THEN
        XCTAssertEqual(try XCTUnwrap(row)["Name"] as String, "Alice")
    }
    
    func testIndependentSingleSQLRowNil() throws {
        // GIVEN
        try db.populateStore()

        // WHEN
        let row = try db
            .prepare("SELECT Name FROM Persons ORDER BY Level ASC")
            .row()

        // THEN
        XCTAssertNil(try XCTUnwrap(row)["Level"] as Int?)
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
        try execute("""
        CREATE TABLE Persons
        (
            Id INTEGER PRIMARY KEY NOT NULL,
            Name VARCHAR,
            Level INTEGER
        )
        """)

        let insertUsersStatement = try self.prepare("""
        INSERT INTO Users (Name, Level)
        VALUES (?, ?)
        """)

        try insertUsersStatement
            .bind("Alice", Int64(80))
            .execute()

        try insertUsersStatement.reset()

        try insertUsersStatement
            .bind("Bob", Int64(90))
            .execute()
        
        let insertPersonsStatement = try self.prepare("""
        INSERT INTO Persons (Name, Level)
        VALUES (?, ?)
        """)

        try insertPersonsStatement
            .bind("Alice", Int64(80))
            .execute()

        try insertPersonsStatement.reset()

        try insertPersonsStatement
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
private struct Person: Hashable, SQLRowDecodable {
    let name: String
    let level: Int64?

    init(name: String, level: Int64?) {
        self.name = name
        self.level = level
    }

    init(row: SQLRow) throws {
        self.name = row["Name"]
        self.level = row["Level"]
    }
}
