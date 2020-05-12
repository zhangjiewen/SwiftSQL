// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3

/// A database connection.
///
/// When deallocated, the connection gets closed automatically.
///
/// # Concurrency
///
/// For more details about using multiple database connections to improve concurrency, please refer to the
/// [documentation](https://www.sqlite.org/isolation.html).
public final class SQLConnection {
    private(set) var ref: OpaquePointer!

    /// Opens a new database read-write connection with the given url. If the
    /// database doesn't exist, creats it. Throws an `SQLError` if it fails open a connection.
    ///
    /// - parameter url: Database URL.
    public convenience init(url: URL) throws {
        try self.init(location: .disk(url: url))
    }

    /// Opens a new database connection with the given parameters. Throws an `SQLError`
    /// if it fails open a connection.
    ///
    /// - parameter mode: Specifies whether open the database for reading, writing
    /// or both, and whether to create it on write. `.readwrite(create: true)` by default.
    /// - parameter options: See `SQLConnectionOptions` for more information.
    public init(location: Location, mode: Mode = .readwrite(create: true), options: Options = Options()) throws {
        let path: String
        var flags: Int32 = 0

        switch mode {
        case .readonly:
            flags |= SQLITE_OPEN_READONLY
        case let .readwrite(create):
            flags |= SQLITE_OPEN_READWRITE
            if create {
                 flags |= SQLITE_OPEN_CREATE
            }
        }
        switch location {
        case let .disk(url):
            path = url.absoluteString
        case let .memory(name):
            path = name
            if name != ":memory:" {
                flags |= SQLITE_OPEN_MEMORY
            }
        case .temporary:
            path = ""
        }

        flags |= options.isSharedCacheEnabled ?
            SQLITE_OPEN_SHAREDCACHE :
            SQLITE_OPEN_PRIVATECACHE

        switch options.threadingMode {
        case .default:
            break // Do nothing
        case .multiThreaded:
            flags |= SQLITE_OPEN_NOMUTEX
        case .serialized:
            flags |= SQLITE_OPEN_FULLMUTEX
        }

        try isOK(sqlite3_open_v2(path, &ref, flags, nil))
    }

    deinit {
         try? close()
     }

    /// Closes the connection.
    ///
    /// Applications should finalize all prepared statements, close all BLOB handles,
    /// and finish all backup objects associated with the connection object prior
    /// to attempting to close it. If close() is called on a database connection
    /// that still has outstanding prepared statements, BLOB handles, backup objects
    /// then it completes successfully and the deallocation of resources is deferred
    /// until all prepared statements, BLOB handles, and backup objects are also destroyed.
    public func close() throws {
        try isOK(sqlite3_close_v2(ref))
    }

    // MARK: Execute

    /// Runs the given one-shot SQL statement.
    ///
    /// - note: Uses [sqlite3_exec](https://www.sqlite.org/c3ref/exec.html).
    public func execute(_ sql: String) throws {
        try isOK(sqlite3_exec(ref, sql, nil, nil, nil))
    }

    // MARK: Private (Compiling Statements)

    #warning("TODO: find a better name")
    public func statement(_ sql: String) throws -> SQLStatement {
        var ref: OpaquePointer!
        try isOK(sqlite3_prepare_v2(self.ref, sql, -1, &ref, nil))
        return SQLStatement(db: self, ref: ref)
    }

    // MARK: Private

    @discardableResult
    private func isOK(_ code: Int32) throws -> Int32 {
        guard let error = SQLError(code: code, db: ref) else { return code }
        throw error
    }
}

// MARK: - SQLConnection (Options)

public extension SQLConnection {
    enum Location {
        /// Database stored on disk.
        case disk(url: URL)
        /// The database will be opened as an in-memory database. The database
        /// is named by the "filename" argument for the purposes of cache-sharing,
        /// if shared cache mode is enabled, but the "filename" is otherwise ignored.
        ///
        /// The default name is `:memory:` which creates a private, temporary
        /// in-memory database for the connection. This in-memory database will
        /// vanish when the database connection is closed.
        case memory(name: String = ":memory:")

        /// A private, temporary on-disk database will be created. This private
        /// database will be automatically deleted as soon as the database
        /// connection is closed.
        case temporary
    }

    enum Mode {
        /// The database is opened in read-only mode. If the database does not
        /// already exist, an error is returned.
        case readonly
        /// The database is opened for reading and writing if possible, or reading only
        /// if the file is write protected by the operating system. In either case the
        /// database must already exist, otherwise an error is returned.
        ///
        /// - parameter create: The database is created if it does not already exist.
        /// `true` by default.
        case readwrite(create: Bool = true)
    }

    struct Options {
        /// SQLite includes a special "shared-cache" mode (disabled by default)
        /// intended for use in embedded servers. If shared-cache mode is enabled
        /// and a process establishes multiple connections to the same database,
        /// the connections share a single data and schema cache. This can
        /// significantly reduce the quantity of memory and IO required by the system.
        ///
        /// [sharedcache.html](https://www.sqlite.org/sharedcache.html)
        public var isSharedCacheEnabled: Bool

        /// By default, uses `serialized` threading mode.
        public var threadingMode: ThreadingMode

        public init(isSharedCacheEnabled: Bool = false, threadingMode: ThreadingMode = .default) {
            self.isSharedCacheEnabled = isSharedCacheEnabled
            self.threadingMode = threadingMode
        }
    }

    /// A threading mode.
    ///
    /// - note: A single-threaded mode can only be selected at (SQL) compile time.
    ///
    /// - note: [threadsafe.html](https://www.sqlite.org/threadsafe.html)
    enum ThreadingMode {
        /// Use the default theading mode configured when SQL was started.
        case `default`
        /// In this mode, SQLite can be safely used by multiple threads provided
        /// that no single database connection is used simultaneously in two or
        /// more threads.
        case multiThreaded
        /// In serialized mode, SQLite can be safely used by multiple threads
        /// with no restriction.
        case serialized
    }
}
