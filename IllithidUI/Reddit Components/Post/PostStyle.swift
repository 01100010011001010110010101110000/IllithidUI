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

// MARK: - PostStyle

enum PostStyle: String, CaseIterable, Identifiable, Codable {
  case compact
  case classic
  case large

  // MARK: Internal

  var id: String {
    rawValue
  }

  var toolbarIcon: some View {
    Image(systemName: iconName)
      .font(.caption)
  }

  var iconName: String {
    switch self {
    case .compact:
      return "list.dash"
    case .classic:
      return "rectangle.split.3x1"
    case .large:
      return "squares.below.rectangle"
    }
  }
}

// MARK: - PostStyleKey

struct PostStyleKey: EnvironmentKey {
  static var defaultValue: PostStyle = .large
}

extension EnvironmentValues {
  var postStyle: PostStyle {
    get {
      self[PostStyleKey.self]
    }
    set {
      self[PostStyleKey.self] = newValue
    }
  }
}

extension View {
  func postStyle(_ style: PostStyle) -> some View {
    environment(\.postStyle, style)
  }
}
