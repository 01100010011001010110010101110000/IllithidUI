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

import Down

import class Down.Image
import class Down.Link
import class Down.List
import class Down.Text

struct ListTypeKey: EnvironmentKey {
  typealias Value = List.ListType
  static var defaultValue: Value = .bullet
}

struct ListDistanceKey: EnvironmentKey {
  typealias Value = Int
  static var defaultValue: Value = 0
}

extension EnvironmentValues {
  var downListType: ListTypeKey.Value {
    get {
      self[ListTypeKey.self]
    }
    set {
      self[ListTypeKey.self] = newValue
    }
  }

  var downListDistance: ListDistanceKey.Value {
    get {
      self[ListDistanceKey.self]
    }
    set {
      self[ListDistanceKey.self] = newValue
    }
  }
}
