// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3

/// Represents a single row returned by the SQL statement.
public struct SQLRow {
    let statement: SQLStatement // Storing as strong reference doesn't seem to affect performance
    var ref: OpaquePointer { statement.ref }

    #warning("TODO: document")
    public subscript<T: SQLDataType>(index: Int) -> T {
        T.sqlColumn(statement: ref, index: Int32(index))
    }

    public subscript<T: SQLDataType>(index: Int) -> T? {
        if sqlite3_column_type(ref, Int32(index)) == SQLITE_NULL {
            return nil
        } else {
            return T.sqlColumn(statement: ref, index: Int32(index))
        }
    }

    public subscript<T: SQLDataType>(name: String) -> T {
        fatalError()
    }

    public subscript<T: SQLDataType>(name: String) -> T? {
        fatalError()
    }
}
