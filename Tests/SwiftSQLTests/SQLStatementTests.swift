// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import SwiftSQL

final class SQLStatementTests: XCTestCase {
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

    // MARK: Execute

    func testCreateTable() throws {
        // WHEN/THEN
        XCTAssertNoThrow(try db.execute("""
        CREATE TABLE Users
        (
            Id INTEGER PRIMARY KEY NOT NULL,
            Level INTEGER,
            Name VARCHAR
        )
        """))
    }

    // MARK: Binding Parameters

    func testBindParameters() throws {
        /// GIVEN
        try db.createTables()
        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        // WHEN
        try statement
            .bind(Int64(80), at: 0)
            .bind("Alex", at: 1)
            .execute()

        // THEN
        #warning("TODO: execute statement")
    }

    func testBindInt() throws {

    }

    // ...

    func testBindByName() throws {

    }

    func testBindByNameMultiple() throws {

    }

    // MARK: Query

    func testQuery() throws {
        // GIVEN
        try db.createTables()
        try db.populateStore()

        // WHEN
        let statement = try db.statement("""
        SELECT Name, Level
        FROM Users
        ORDER BY Level ASC
        """)

        var objects = [User]()
        while let row = try statement.next() {
            let user = User(name: row[0], level: row[1])
            objects.append(user)
        }

        // THEN
        XCTAssertEqual(objects, [User(name: "Alice", level: 80), User(name: "Bob", level: 90)])
    }
}

private extension SQLConnection {
    func createTables() throws {
        try execute("""
        CREATE TABLE Users
        (
            Id INTEGER PRIMARY KEY NOT NULL,
            Name VARCHAR,
            Level INTEGER
        )
        """)
    }

    func populateStore() throws {
        let statement = try self.statement("""
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

struct User: Hashable {
    let name: String
    let surname: String
    let level: Int64

    init(name: String, surname: String = "", level: Int64) {
        self.name = name
        self.surname = surname
        self.level = level
    }
}
