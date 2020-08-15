//
// AccountData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import Combine
import os.log
import SwiftUI

import Alamofire
import Illithid

class AccountData: ObservableObject {
  @Published private(set) var account: Account?

  @Published private(set) var content: [AccountContent: [Listing.Content]] = [:]

  private var listingAnchors: [AccountContent: ListingParameters] = [:]
  private var isExhausted: [AccountContent: Bool] = [:]

  private let log = OSLog(subsystem: "com.flayware.IllithidUI.accounts", category: .pointsOfInterest)

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

  func loadContent(content: AccountContent, sort: AccountContentSort, topInterval: TopInterval = .day) {
    guard !isExhausted[content, default: false] else { return }
    account?.content(content: content, sort: sort, topInterval: topInterval, parameters: listingAnchors[content]!) { result in
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
}
