// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3
import SwiftSQL

public extension SQLStatement {
    /// Fetches the next row.
    func row<T: SQLRowDecodable>(_ type: T.Type) throws -> T? {
        guard try step() else {
            return nil
        }
        return try T(row: SQLRow(statement: self))
    }

    /// Fetches the first `count` rows returned by the statement. By default,
    /// fetches all rows.
    func rows<T: SQLRowDecodable>(count: Int? = nil, _ type: T.Type) throws -> [T] {
        var objects = [T]()
        let limit = count ?? Int.max
        while let object = try row(T.self), objects.count < limit {
            objects.append(object)
        }
        return objects
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
