// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation

public enum SQLColumnValue {
    case int64(Int64)
    case double(Double)
    case string(String)
    case data(Data)
    case null
}
