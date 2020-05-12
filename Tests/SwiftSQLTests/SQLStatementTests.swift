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

    func testBindUsingIndexes() throws {
        /// GIVEN
        try db.createTables()

        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        // WHEN
        try statement
            .bind(80, at: 0)
            .bind("Alex", at: 1)
            .execute()

        // THEN
        let row = try XCTUnwrap(db.statement("SELECT Level, Name FROM Users").next())
        XCTAssertEqual(row[0], 80)
        XCTAssertEqual(row[1], "Alex")
    }

    func testBindNilUsingIndexes() throws {
        /// GIVEN
        try db.createTables()

        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        // WHEN
        try statement
            .bind(80, at: 0)
            .bind(nil as String?, at: 1)
            .execute()

        // THEN
        let row = try XCTUnwrap(db.statement("SELECT Level, Name FROM Users").next())
        XCTAssertEqual(row[0], 80)
        XCTAssertEqual(row[1] as String?, nil)
    }

    func testBindUsingArray() throws {
        /// GIVEN
        try db.createTables()

        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        // WHEN
        try statement
            .bind([80, "Alex"])
            .execute()

        // THEN
        let row = try XCTUnwrap(db.statement("SELECT Level, Name FROM Users").next())
        XCTAssertEqual(row[0], 80)
        XCTAssertEqual(row[1], "Alex")
    }

    func testBindUsingArrayNilValue() throws {
        /// GIVEN
        try db.createTables()

        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        // WHEN
        try statement
            .bind([80, nil])
            .execute()

        // THEN
        let row = try XCTUnwrap(db.statement("SELECT Level, Name FROM Users").next())
        XCTAssertEqual(row[0], 80)
        XCTAssertEqual(row[1] as String?, nil)
    }

    func testBindUsingVariadics() throws {
        /// GIVEN
        try db.createTables()

        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        // WHEN
        try statement
            .bind(80, "Alex")
            .execute()

        // THEN
        let row = try XCTUnwrap(db.statement("SELECT Level, Name FROM Users").next())
        XCTAssertEqual(row[0], 80)
        XCTAssertEqual(row[1], "Alex")
    }

    func testBindUsingVariadicsNilValue() throws {
        /// GIVEN
        try db.createTables()

        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        // WHEN
        try statement
            .bind(80, nil)
            .execute()

        // THEN
        let row = try XCTUnwrap(db.statement("SELECT Level, Name FROM Users").next())
        XCTAssertEqual(row[0], 80)
        XCTAssertEqual(row[1] as String?, nil)
    }

    func testBindByName() throws {
        /// GIVEN
        try db.createTables()

        try db.statement("INSERT INTO Users (Level, Name) VALUES (?, ?)")
            .bind(80, "Alex")
            .execute()

        // WHEN
        let row = try XCTUnwrap(db
            .statement("SELECT Level, Name FROM Users WHERE Name = :param")
            .bind("Alex", for: ":param")
            .next())

        // THEN
        XCTAssertEqual(row[0], 80)
    }

    func testBindByNameDictionary() throws {
        /// GIVEN
        try db.createTables()

        try db.statement("INSERT INTO Users (Level, Name) VALUES (?, ?)")
            .bind(80, "Alex")
            .execute()

        // WHEN
        let row = try XCTUnwrap(db
            .statement("SELECT Level, Name FROM Users WHERE Name = :param")
            .bind([":param": "Alex"])
            .next())

        // THEN
        XCTAssertEqual(row[0], 80)
    }

    func testClearBinding() throws {
        /// GIVEN
        try db.createTables()

        let statement = try db.statement("""
        INSERT INTO Users (Level, Name)
        VALUES (?, ?)
        """)

        try statement
            .bind(80, nil)
            .execute()

        try db.execute("DELETE FROM Users")

        // WHEN
        try statement
            .reset()
            .clearBindings()
            .bind("Alex", at: 1)
            .execute()

        // THEN
        let row = try XCTUnwrap(db.statement("SELECT Level, Name FROM Users").next())
        XCTAssertEqual(row[0] as Int?, nil)
        XCTAssertEqual(row[1], "Alex")
    }

    // MARK: Next

    func testNext() throws {
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
        XCTAssertEqual(objects, [
            User(name: "Alice", level: 80),
            User(name: "Bob", level: 90)
        ])
    }

    // MARK: Misc

    func testSQL() throws {
        // GIVEN
        try db.createTables()
        let statement = try db.statement("SELECT * FROM Users")

        // THEN
        XCTAssertEqual(statement.sql, "SELECT * FROM Users")
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
