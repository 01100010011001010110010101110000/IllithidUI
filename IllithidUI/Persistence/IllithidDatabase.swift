// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

import GRDB

// MARK: - IllithidDatabase

class IllithidDatabase {
  // MARK: Lifecycle

  private init(_ dbWriter: DatabaseWriter) throws {
    self.dbWriter = dbWriter
    try migrator.migrate(dbWriter)
  }

  // MARK: Private

  private let dbWriter: DatabaseWriter

  private var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    // For ease of development, wipe the database when migration schemas do not match that of the database
    #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
    #endif

    // --- BEGIN REGISTER MIGRATIONS
    // --- END REGISTER MIGRATIONS
    return migrator
  }
}

// MARK: - Persistence and initialization

extension IllithidDatabase {
  static let shared = makeShared()

  private static func makeShared() -> IllithidDatabase {
    let fileManager = FileManager()
    do {
      let folderUrl = try fileManager
        .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent("database", isDirectory: true)
      try fileManager.createDirectory(at: folderUrl, withIntermediateDirectories: true)
      try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: folderUrl.path)

      let dbUrl = folderUrl.appendingPathComponent("illithid.sqlite")
      let dbPool = try DatabasePool(path: dbUrl.path)
      print("Database URL: \(dbUrl.absoluteString)")

      let illithidDatabase = try IllithidDatabase(dbPool)

      return illithidDatabase
    } catch {
      fatalError("Unhandled exception: \(error)")
    }
  }

  static func ephemeral() -> IllithidDatabase {
    try! IllithidDatabase(DatabaseQueue())
  }
}
