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

import Illithid

// MARK: - FrontPage + Iconic

extension FrontPage: Iconic {
  var systemImageIconName: String {
    switch self {
    case .all:
      return "asterisk.circle"
    case .home:
      return "house"
    case .popular:
      return "arrow.up.right.square"
    case .random:
      return "shuffle"
    }
  }
}

// MARK: - IllithidPages + Iconic

extension IllithidPages: Iconic {
  var systemImageIconName: String {
    switch self {
    case .account:
      return "person.crop.circle"
    case .search:
      return "magnifyingglass"
    }
  }
}
