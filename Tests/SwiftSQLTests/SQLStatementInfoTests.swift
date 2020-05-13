// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import SwiftSQL

final class SQLStatementInfoTests: XCTestCase {
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

    func testSQL() throws {
        // GIVEN
        try db.createTables()
        let statement = try db.statement("SELECT * FROM Users")

        // THEN
        XCTAssertEqual(statement.info.sql, "SELECT * FROM Users")
    }

    func testColumnCount() throws {
        // GIVEN
        try db.createTables()
        let statement = try db.statement("SELECT * FROM Users")

        // THEN
        XCTAssertEqual(statement.info.columnCount, 3)
    }

    func testColumnNameAtIndex() throws {
        // GIVEN
        try db.createTables()
        let statement = try db.statement("SELECT * FROM Users")

        // THEN
        XCTAssertEqual(statement.info.columnName(at: 1), "Name")
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
