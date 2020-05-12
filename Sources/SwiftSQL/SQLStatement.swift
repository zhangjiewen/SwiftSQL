// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3

/// An SQL statement compiled into bytecode.
///
/// An instance of this object represents a single SQL statement that has been
/// compiled into binary form and is ready to be evaluated.
///
/// Think of each SQL statement as a separate computer program. The original SQL
/// text is source code. A prepared statement object is the compiled object code.
/// All SQL must be converted into a prepared statement before it can be run.
///
/// The life-cycle of a prepared statement object usually goes like this:
///
/// 1. Create the prepared statement object using a connection:
///
///     let db = try SQLConnection(url: <#store_url#>)
///     let statement = try db.statement("""
///     INSERT INTO Users (Name, Surname) VALUES (?, ?)
///     """)
///
/// 2. Bind values to parameters using one of the `bind()` methods. The provided
/// values must be one of the data types supported by SQLite (see `SQLDataType` for
/// more info)
///
///     try statement.bind("Alexander", "Grebenyuk")
///
/// 3. Execute the statement (you can chain it after `bind()`)
///
///     // Using "call as function"
///     try statement()
///
///     // Using `execute()` method
///     try statement.execute()
///
///     // If it's a `SELECT` query
///     while let row = try statement.next() {
///         let name: String = row[0]
///     }
///
/// 4. (Optional) To reuse the compiled statementt, reset it and go back to step 2,
/// do this zero or more times.
///
///     try statement.reset()
///
/// The compiled statement is going to be automatically destroyed when the
/// `SQLStatement` object gets deallocated.
public final class SQLStatement {
    let db: SQLConnection
    let ref: OpaquePointer

    init(db: SQLConnection, ref: OpaquePointer) {
        self.db = db
        self.ref = ref
    }

    deinit {
        sqlite3_finalize(ref)
    }

    // MARK: Execute

    /// Executes the statement and returns `true` if the next row is available.
    /// Returns `false` if the statement is finished executing and no more data
    /// is available. Throws an error if an error is encountered.
    public func next() throws -> SQLRow? {
        guard try isOK(sqlite3_step(ref)) == SQLITE_ROW else {
            return nil
        }
        return SQLRow(statement: self)
    }

    @discardableResult
    public func execute() throws -> SQLStatement {
        try isOK(sqlite3_step(ref))
        return self
    }

    // MARK: Binding Parameters

    #warning("TODO: document")
    #warning("TODO: bind should throw")
    @discardableResult
    public func bind(_ parameters: SQLDataType?...) throws -> Self {
        try bind(parameters)
        return self
    }

    @discardableResult
    public func bind(_ parameters: [SQLDataType?]) throws -> Self {
        for (index, value) in zip(parameters.indices, parameters) {
            try _bind(value, at: Int32(index))
        }
        return self
    }

    @discardableResult
    public func bind(_ parameters: [String: SQLDataType?]) throws -> Self {
        for (name, value) in parameters {
            try _bind(value, for: name)
        }
        return self
    }

    @discardableResult
    public func bind<T: SQLDataType>(_ value: T?, for name: String) throws -> Self {
        let index = sqlite3_bind_parameter_index(ref, name)
        guard index > 0 else { fatalError("Parameter not found: \(name)") }
        try bind(value, at: Int(index))
        return self
    }

    /// - parameter index: The index starts at 0.
    @discardableResult
    public func bind<T: SQLDataType>(_ value: T?, at index: Int) throws -> Self {
        let index = index + 1
        if let value = value {
            value.sqlBind(statement: ref, index: Int32(index))
        } else {
            sqlite3_bind_null(ref, Int32(index))
        }
        return self
    }

    private func _bind(_ value: SQLDataType?, for name: String) throws {
        let index = sqlite3_bind_parameter_index(ref, name)
        guard index > 0 else { fatalError("Parameter not found: \(name)") }
        try _bind(value, at: Int32(index))
    }

    private func _bind(_ value: SQLDataType?, at index: Int32) throws {
        let index = index + 1
        if let value = value {
            value.sqlBind(statement: ref, index: index)
        } else {
            sqlite3_bind_null(ref, index)
        }
    }

    /// Clears bindings.
    ///
    /// It is not commonly useful to evaluate the exact same SQL statement more
    /// than once. More often, one wants to evaluate similar statements. For example,
    /// you might want to evaluate an INSERT statement multiple times with different
    /// values. Or you might want to evaluate the same query multiple times using
    /// a different key in the WHERE clause. To accommodate this, SQLite allows SQL
    /// statements to contain parameters which are "bound" to values prior to being
    /// evaluated. These values can later be changed and the same prepared statement
    /// can be evaluated a second time using the new values.
    ///
    /// `clearBindings()` allows you to clear those bound values. It is not required
    /// to call `clearBindings()` every time. Simplify overwriting the existing values
    /// does the trick.
    public func clearBindings() throws {
        try isOK(sqlite3_clear_bindings(ref))
    }

    // MARK: Reset

    /// Resets the expression and prepares it for the new execution.
    ///
    /// SQLite allows the same prepared statement to be evaluated multiple times.
    /// After a prepared statement has been evaluated it can be reset in order to
    /// be evaluated again by a call to `reset()`. Reusing compiled statements
    /// can give a significant performance improvement.
    public func reset() throws {
        try isOK(sqlite3_reset(ref))
    }

    // MARK: Private

    @discardableResult
    private func isOK(_ code: Int32) throws -> Int32 {
        guard let error = SQLError(code: code, db: db.ref) else { return code }
        throw error
    }
}

#warning("TODO: is retaining statement fine in terms of performance?")
public struct SQLRow {
    let statement: SQLStatement // Storing as strong reference doesn't seem to affect performance
    var ref: OpaquePointer { statement.ref }

    #warning("TODO: document")
    #warning("TODO: add null checks")
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
