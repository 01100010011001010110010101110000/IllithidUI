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

// MARK: - NavigationStyle

enum NavigationStyle: String, CaseIterable, Identifiable, Codable {
  case multiColumn
  case linear

  // MARK: Internal

  var id: String { rawValue }
}

// MARK: - NavigationStyleKey

struct NavigationStyleKey: EnvironmentKey {
  static var defaultValue: NavigationStyle = .linear
}

extension EnvironmentValues {
  var navigationStyle: NavigationStyle {
    get {
      self[NavigationStyleKey.self]
    }
    set {
      self[NavigationStyleKey.self] = newValue
    }
  }
}

extension View {
  func navigationStyle(_ style: NavigationStyle) -> some View {
    environment(\.navigationStyle, style)
  }
}
