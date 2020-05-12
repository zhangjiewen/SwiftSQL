<p align="left">
<img src="https://img.shields.io/badge/platforms-iOS%2C%20macOS%2C%20watchOS%2C%20tvOS-lightgrey.svg">
<img src="https://github.com/kean/SwiftSQL/workflows/CI/badge.svg">
</p>

**SwiftSQL** introduces a Swift API for [SQLite](https://www.sqlite.org/index.html). It doesn't have any ORM-like features. It maps directly to the SQLite concepts with some affordances to make it great a Swift API. It is feature-complete, fully documented and tested.

<br/>

# Usage

### `SQLStatement`

An instance of `SQLStatement` represents a single SQL statement that has been compiled into binary form and is ready to be evaluated.

Think of each SQL statement as a separate computer program. The original SQL text is source code. A prepared statement object is the compiled object code. All SQL must be converted into a prepared statement before it can be run.

#### Lifecycle

The life-cycle of a prepared statement object usually goes like this:

1. Create the prepared statement object using a connection:

```swift
let db = try SQLConnection(url: storeURL)
let statement = try db.statement("""
INSERT INTO Users (Name, Surname)
VALUES (?, ?)
""")
```

2. Bind values to parameters using one of the `bind()` methods. The provided values must be one of the data types supported by SQLite (see `SQLDataType` for more info)

```swift
try statement.bind("Alexander", "Grebenyuk")
```

3. Execute the statement.

```swift
// Using `execute()` method
try statement.execute()

// If it's a `SELECT` query
// See `SQLRow` type for more info how to read data from the columns.
while let row = try statement.next() {
    let name: String = row[0]
}
```

4. (Optional) To reuse the compiled statementt, reset it and go back to step 2,
do this zero or more times.

```swift
try statement.reset()
```

The compiled statement is going to be automatically destroyed when the
`SQLStatement` object gets deallocated.

#### Chaining

All of the methods outlined in the previous section are chainable:

```swift
try db.statement("INSERT INTO Users (Name) VALUES (?)")
    .bind("Alex")
    .execute()
```

### `SQLDataType`

`SQLDataType` makes it possible to use native `Swift` types to work with SQLite. Supported types:

- `Int`
- `Int32`
- `Int64`
- `String`
- `Data`

> To add support for custom data types, like `Bool` or `Date`, see [Advanced Usage Guide](https://github.com/kean/SwiftSQL/blob/0.1.0/Docs/advanced-usage-guide.md) 

# Minimum Requirements

| SwiftSQL          | Swift           | Xcode           | Platforms                                         |
|---------------|-----------------|-----------------|---------------------------------------------------|
| SwiftSQL 0.1      | Swift 5.2       | Xcode 11.3      | iOS 11.0 / watchOS 4.0 / macOS 10.13 / tvOS 11.0  |

# License

SwiftSQL is available under the MIT license. See the LICENSE file for more info.

