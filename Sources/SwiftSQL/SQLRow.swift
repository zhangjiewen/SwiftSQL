// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3

/// Represents a single row returned by the SQL statement.
public struct SQLRow {
    let statement: SQLStatement // Storing as strong reference doesn't seem to affect performance
    var ref: OpaquePointer { statement.ref }

    /// Returns a single column of the current result row of a query.
    ///
    /// If the SQL statement does not currently point to a valid row, or if the
    /// column index is out of range, the result is undefined.
    ///
    /// - parameter index: The leftmost column of the result set has the index 0.
    public subscript<T: SQLDataType>(index: Int) -> T {
        T.sqlColumn(statement: ref, index: Int32(index))
    }

    /// Returns a single column of the current result row of a query. If the
    /// value is `Null`, returns `nil.`
    ///
    /// If the SQL statement does not currently point to a valid row, or if the
    /// column index is out of range, the result is undefined.
    ///
    /// - parameter index: The leftmost column of the result set has the index 0.
    public subscript<T: SQLDataType>(index: Int) -> T? {
        if sqlite3_column_type(ref, Int32(index)) == SQLITE_NULL {
            return nil
        } else {
            return T.sqlColumn(statement: ref, index: Int32(index))
        }
    }

    /// Returns a single column of the current result row of a query.
    public subscript<T: SQLDataType>(name: String) -> T {
        fatalError()
    }

    /// Returns a single column of the current result row of a query.
    public subscript<T: SQLDataType>(name: String) -> T? {
        fatalError()
    }
}
