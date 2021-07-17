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

import Illithid

// MARK: - IllithidPages

enum IllithidPages: String, CaseIterable, Identifiable {
  /// The user's account page
  case account
  /// Illithid's search page
  case search

  // MARK: Public

  public var title: String {
    rawValue.capitalized
  }

  // MARK: Internal

  var id: String {
    switch self {
    case .account:
      return "__illithid_account_page__"
    case .search:
      return "__illithid_search_page__"
    }
  }
}

extension IllithidPages {
  @ViewBuilder var destinationView: some View {
    switch self {
    case .account:
      accountView
    case .search:
      SearchView()
    }
  }

  @ViewBuilder private var accountView: some View {
    if let account = Illithid.shared.accountManager.currentAccount {
      AccountView(account: account)
    } else {
      Text("There is no logged in account")
    }
  }
}
