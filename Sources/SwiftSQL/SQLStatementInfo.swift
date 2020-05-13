// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3

/// Returns additional information about the statement.
public struct SQLStatementInfo {
    let statement: SQLStatement
    private var ref: OpaquePointer { statement.ref }

    /// Returns true (non-zero) if the statement has been stepped at least once
    /// using `next()`, but has neither run to completion nor been reset.
    public var isBusy: Bool {
        sqlite3_stmt_busy(ref) != 0
    }

    /// Returns true if the statement makes no direct changes to the content of the database file.
    ///
    /// - note: For more information see [documentation](https://www.sqlite.org/c3ref/stmt_readonly.html).
    public var isReadOnly: Bool {
        sqlite3_stmt_readonly(ref) != 0
    }

    /// Returns the SQL text used to create the statement.
    public var sql: String {
        String(cString: sqlite3_sql(ref))
    }

    /// Returns the SQL text used to create the statement with the bound parameters expanded.
    ///
    /// Note that this API can return `nil` if there is insufficient memory to
    /// hold the result, or if the result would exceed the maximum string length
    /// determined by the [SQLITE_LIMIT_LENGTH].
    public var expandedSQL: String? {
        sqlite3_expanded_sql(ref).map { String(cString: $0) }
    }

    /// Return the number of columns in the result set returned by the statement.
    ///
    /// If this routine returns 0, that means the prepared statement returns no data
    /// (for example an UPDATE). However, just because this routine returns a positive
    /// number does not mean that one or more rows of data will be returned.
    public var columnCount: Int {
        Int(sqlite3_column_count(ref))
    }

    /// These routines return the name assigned to a particular column in the result
    /// set of a SELECT statement.
    ///
    /// The name of a result column is the value of the "AS" clause for that column,
    /// if there is an AS clause. If there is no AS clause then the name of the
    /// column is unspecified and may change from one release of SQLite to the next.
    public func columnName(at index: Int) -> String {
        String(cString: sqlite3_column_name(ref, Int32(index)))
    }
}
