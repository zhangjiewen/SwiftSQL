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
    func rows<T: SQLRowDecodable>(_ type: T.Type, count: Int? = nil) throws -> [T] {
        var objects = [T]()
        let limit = count ?? Int.max
        if let count = count {
            objects.reserveCapacity(count)
        }
        while let object = try row(T.self), objects.count < limit {
            objects.append(object)
        }
        return objects
    }
    
    /// Fetches the next row as `SQLRow`.
    func row() throws -> SQLRow? {
        guard try step() else {
            return nil
        }
        return SQLRow(statement: self)
    }

    /// Fetches the first `count` rows as `SQLRow`s returned by the statement. By default,
    /// fetches all rows.
    func rows(count: Int? = nil) throws -> [SQLRow] {
        var objects = [SQLRow]()
        let limit = count ?? Int.max
        if let count = count {
            objects.reserveCapacity(count)
        }
        while let object = try row(), objects.count < limit {
            objects.append(object)
        }
        return objects
    }
}

/// Represents a single row returned by the SQL statement.
public struct SQLRow {

    public init(statement: SQLStatement) {
        values = (0..<statement.columnCount).map { index in
            statement.column(at: index)
        }
        columnIndicesByNames = Dictionary(uniqueKeysWithValues: (0..<statement.columnCount).map { index in
            (statement.columnName(at: index), index)
        })
    }

    /// Returns a single column of the current result row of a query.
    ///
    /// If the SQL statement does not currently point to a valid row, or if the
    /// column index is out of range, the result is undefined.
    ///
    /// - parameter index: The leftmost column of the result set has the index 0.
    public subscript<T: InitializableBySQLColumnValue>(index: Int) -> T {
        let value = values[index]
        guard let convertedValue = T(sqlColumnValue: value) else {
            fatalError("Could not convert \(type(of: value)). Make sure target type (\(T.self)) correctly implements convert(from:).")
        }
        return convertedValue
    }

    /// Returns a single column of the current result row of a query. If the
    /// value is `Null`, returns `nil.`
    ///
    /// If the SQL statement does not currently point to a valid row, or if the
    /// column index is out of range, the result is undefined.
    ///
    /// - parameter index: The leftmost column of the result set has the index 0.
    public subscript<T: InitializableBySQLColumnValue>(index: Int) -> T? {
        return T(sqlColumnValue: values[index])
    }
    
    /// Returns a single column (by its name) of the current result row of a query.
    ///
    /// If the SQL statement does not currently point to a valid row, the result is undefined.
    /// If the passed columnName doesn't point to a valid column name, a fatal error is raised.
    ///
    /// - parameter columnName: The name of the column.
    public subscript<T: InitializableBySQLColumnValue>(columnName: String) -> T {
        guard let columnIndex = columnIndicesByNames[columnName] else {
            fatalError("No such column \(columnName)")
        }
        return self[columnIndex]
    }
    
    /// Returns a single column (by its name) of the current result row of a query.
    ///
    /// If the SQL statement does not currently point to a valid row, the result is undefined.
    /// If the passed columnName doesn't point to a valid column name, nil is returned.
    ///
    /// - parameter columnName: The name of the column.
    public subscript<T: InitializableBySQLColumnValue>(columnName: String) -> T? {
        guard let columnIndex = columnIndicesByNames[columnName] else {
            return nil
        }
        return self[columnIndex]
    }
    
    private let values: [SQLColumnValue]
    private let columnIndicesByNames: [String : Int]
}

public protocol SQLRowDecodable {
    init(row: SQLRow) throws
}

public protocol InitializableBySQLColumnValue {
    init?(sqlColumnValue: SQLColumnValue)
}
