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

import Combine
import os.log
import SwiftUI

import Alamofire
import Illithid

class AccountData: ObservableObject {
  // MARK: Lifecycle

  private init(_ account: Account?) {
    self.account = account
    AccountContent.allCases.forEach { type in
      content[type] = []
      listingAnchors[type] = ListingParameters()
    }
  }

  convenience init(account: Account) {
    self.init(account)
  }

  convenience init(name: String) {
    self.init(nil)
    Account.fetch(username: name) { result in
      switch result {
      case let .success(account):
        self.account = account
      case let .failure(error):
        self.account = nil
        Illithid.shared.logger.errorMessage("Failure fetching account: \(error)")
      }
    }
  }

  // MARK: Internal

  @Published private(set) var account: Account?

  @Published private(set) var content: [AccountContent: [Listing.Content]] = [:]
  @Published private(set) var isLoading: [AccountContent: Bool] = [:]

  func reload(content: AccountContent, sort: AccountContentSort, topInterval: TopInterval = .day) {
    requests[content]?.cancel()
    clearContent(content: content)
    loadContent(content: content, sort: sort, topInterval: topInterval)
  }

  func loadContent(content: AccountContent, sort: AccountContentSort, topInterval: TopInterval = .day) {
    guard !isExhausted[content, default: false] else { return }
    isLoading[content] = true
    requests[content] = account?.content(content: content, sort: sort, topInterval: topInterval, parameters: listingAnchors[content]!) { result in
      self.isLoading[content] = false
      switch result {
      case let .success(listing):
        self.content[content]?.append(contentsOf: listing.children)
        self.listingAnchors[content]?.after = listing.after ?? ""
        self.isExhausted[content] = listing.after == nil
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to load \(content) for \(self.account?.name ?? "No account"): \(error)")
      }
    }
  }

  func clearContent(content: AccountContent) {
    isExhausted[content] = false
    listingAnchors[content] = .init()
    self.content[content]?.removeAll(keepingCapacity: true)
  }

  // MARK: Private

  private var listingAnchors: [AccountContent: ListingParameters] = [:]
  private var isExhausted: [AccountContent: Bool] = [:]
  private var requests: [AccountContent: DataRequest] = [:]

  private let log = OSLog(subsystem: "com.flayware.IllithidUI.accounts", category: .pointsOfInterest)
}
