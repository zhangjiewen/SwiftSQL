// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3
import SwiftSQL

public extension SQLStatement {
    func next() throws -> SQLRow? {
        guard try self.step() else {
            return nil
        }
        return SQLRow(statement: self)
    }

    func all<T: SQLRowDecodable>(_ type: T.Type) throws -> [T] {
        var objects = [T]()
        while let object = try next(T.self) {
            objects.append(object)
        }
        return objects
    }

    func next<T: SQLRowDecodable>(_ type: T.Type) throws -> T? {
        guard let row = try next() else {
            return nil
        }
        return try T(row: row)
    }
}

/// Represents a single row returned by the SQL statement.
///
/// - warning: This is a leaky abstraction. This is not a real value type, it
/// just wraps the underlying statement. If the statement moves to the next
/// row by calling `step()`, the row is also going to point to the new row.
public struct SQLRow {
    /// The underlying statement.
    public let statement: SQLStatement // Storing as strong reference doesn't seem to affect performance

    public init(statement: SQLStatement) {
        self.statement = statement
    }

    /// Returns a single column of the current result row of a query.
    ///
    /// If the SQL statement does not currently point to a valid row, or if the
    /// column index is out of range, the result is undefined.
    ///
    /// - parameter index: The leftmost column of the result set has the index 0.
    public subscript<T: SQLDataType>(index: Int) -> T {
        statement.column(at: index)
    }

    /// Returns a single column of the current result row of a query. If the
    /// value is `Null`, returns `nil.`
    ///
    /// If the SQL statement does not currently point to a valid row, or if the
    /// column index is out of range, the result is undefined.
    ///
    /// - parameter index: The leftmost column of the result set has the index 0.
    public subscript<T: SQLDataType>(index: Int) -> T? {
        statement.column(at: index)
    }
}

public protocol SQLRowDecodable {
    init(row: SQLRow) throws
}
