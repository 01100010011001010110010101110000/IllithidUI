//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import Combine
import SwiftUI

import Illithid

final class AccountData: ObservableObject {
  @Published private(set) var account: Account?
  @Published private(set) var comments: [Comment] = []
  @Published private(set) var submissions: [Post] = []

  init(account: Account?) {
    self.account = account
    if let account = account { loadAccount(account) }
  }

  convenience init(name: String) {
    self.init(account: nil)
    Account.fetch(name: name) { result in
      switch result {
      case let .success(account):
        self.account = account
        self.loadAccount(account)
      case let .failure(error):
        self.account = nil
        print("Failure fetching account: \(error)")
      }
    }
  }

  fileprivate func loadAccount(_ account: Account) {
    account.comments { result in
      switch result {
      case let .success(comments):
        self.comments.append(contentsOf: comments)
      case let .failure(error):
        print("Failed to fetch comments: \(error)")
      }
    }
    account.submittedPosts { result in
      switch result {
      case let .success(posts):
        self.submissions.append(contentsOf: posts)
      case let .failure(error):
        print("Failed to fetch submissions: \(error)")
      }
    }
  }
}
