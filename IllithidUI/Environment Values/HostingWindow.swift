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

import SwiftUI

// MARK: - Weak

@dynamicMemberLookup
final class Weak<Value: AnyObject> {
  // MARK: Lifecycle

  init(_ value: Value?) {
    self.value = value
  }

  // MARK: Internal

  subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T? {
    value?[keyPath: keyPath]
  }

  // MARK: Private

  private weak var value: Value?
}

// MARK: - HostingWindowKey

struct HostingWindowKey: EnvironmentKey {
  #if canImport(UIKit)
    typealias Value = Weak<UIWindow>
  #elseif canImport(AppKit)
    typealias Value = Weak<NSWindow>
  #else
    #error("Unsupported platform")
  #endif

  static let defaultValue: Value = .init(nil)
}

extension EnvironmentValues {
  var hostingWindow: HostingWindowKey.Value {
    get {
      self[HostingWindowKey.self]
    }
    set {
      self[HostingWindowKey.self] = newValue
    }
  }
}
