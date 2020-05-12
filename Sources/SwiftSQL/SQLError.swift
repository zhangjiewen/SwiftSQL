// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SQLite3

#warning("TODO: update documentation")
public struct SQLError: Swift.Error, CustomStringConvertible {
    // MARK: Properties

    /// The [code](https://www.sqlite.org/c3ref/c_abort.html) of the specific error encountered by SQLite.
    public let code: Int32

    /// The [message](https://www.sqlite.org/c3ref/errcode.html) of the specific error encountered by SQLite.
    public var message: String

    /// A textual description of the [error code](https://www.sqlite.org/c3ref/errcode.html).
    public var codeDescription: String { return String(cString: sqlite3_errstr(code)) }

    // MARK: Initialization

    init?(code: Int32, db: OpaquePointer) {
        // This is much faster than using a set for just three values.
        guard !(code == SQLITE_ROW || code == SQLITE_OK || code == SQLITE_DONE) else { return nil }

        self.code = code
        self.message = String(cString: sqlite3_errmsg(db))
    }

    public init(code: Int32, message: String) {
        self.code = code
        self.message = message
    }

    public var description: String {
        let messageArray = [
            "message=\"\(message)\"",
            "code=\(code)",
            "codeDescription=\"\(codeDescription)\""
        ]

        return "{ " + messageArray.joined(separator: ", ") + " }"
    }
}
