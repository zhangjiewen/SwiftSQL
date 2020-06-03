// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3

/// Represents a data type supported by SQLite.
///
/// - note: To add support for custom data types, like `Bool` or `Date`, see
/// [Advanced Usage Guide](https://github.com/kean/SwiftSQL/blob/0.1.0/Docs/advanced-usage-guide.md)
public protocol SQLDataType {
    func sqlBind(statement: OpaquePointer, index: Int32)
    static func sqlColumn(statement: OpaquePointer, index: Int32) -> Self
    static func convert(from value: Any) -> Self?
}

extension Int: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_int64(statement, index, Int64(self))
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> Int {
        Int(sqlite3_column_int64(statement, index))
    }
    
    public static func convert(from value: Any) -> Int? {
        guard let int64 = value as? Int64 else { return nil }
        return Int(int64)
    }
}

extension Int32: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_int(statement, index, self)
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> Int32 {
        sqlite3_column_int(statement, index)
    }
    
    public static func convert(from value: Any) -> Self? {
        guard let int64 = value as? Int64 else { return nil }
        return Int32(int64)
    }
}

extension Int64: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_int64(statement, index, self)
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> Int64 {
        sqlite3_column_int64(statement, index)
    }
    
    public static func convert(from value: Any) -> Self? { value as? Self }
}

extension Double: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_double(statement, index, self)
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> Double {
        sqlite3_column_double(statement, index)
    }
    
    public static func convert(from value: Any) -> Self? { value as? Self }
}

extension String: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_text(statement, index, self, -1, SQLITE_TRANSIENT)
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> String {
        guard let pointer = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: pointer)
    }
    
    public static func convert(from value: Any) -> Self? { value as? Self }
}

extension Data: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_blob(statement, Int32(index), Array(self), Int32(count), SQLITE_TRANSIENT)
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> Data {
        guard let pointer = sqlite3_column_blob(statement, Int32(index)) else {
            return Data()
        }
        let count = Int(sqlite3_column_bytes(statement, Int32(index)))
        return Data(bytes: pointer, count: count)
    }
    
    public static func convert(from value: Any) -> Self? { value as? Self }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
