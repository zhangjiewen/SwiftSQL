## Extending Supported Data Types

Use `SQLDataType` to add support for additional data types.

```swift
extension Date: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_double(statement, index, timeIntervalSince1970)
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> Date {
        Date(timeIntervalSince1970: sqlite3_column_double(statement, index))
    }
}
```

```swift
extension Bool: SQLDataType {
    public func sqlBind(statement: OpaquePointer, index: Int32) {
        sqlite3_bind_int(statement, index, Int32(self ? 1 : 0))
    }

    public static func sqlColumn(statement: OpaquePointer, index: Int32) -> Bool {
        sqlite3_column_int(statement, index) == 0
    }
}
```
