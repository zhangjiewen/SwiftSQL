// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import SwiftSQL

final class TempDirectory {
    let url: URL

    deinit {
        try? destroy()
    }

    init() throws {
        url = FileManager().temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
    }

    func file(named name: String) -> URL {
        url.appendingPathComponent(name)
    }

    func destroy() throws  {
        try FileManager.default.removeItem(at: url)
    }
}

struct User: Hashable {
    let name: String
    let surname: String
    let level: Int64

    init(name: String, surname: String = "", level: Int64) {
        self.name = name
        self.surname = surname
        self.level = level
    }
}
