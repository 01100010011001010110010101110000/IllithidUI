//
// AccountData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 4/2/20
//

import Combine
import os.log
import SwiftUI

import Illithid

class AccountData: ObservableObject {
  @Published private(set) var account: Account?
  @Published private(set) var overview: [Listing.Content] = []

  @Published private(set) var saved: [Listing.Content] = []
  @Published private(set) var hidden: [Post] = []

  @Published private(set) var upvoted: [Post] = []
  @Published private(set) var downvoted: [Post] = []

  @Published private(set) var comments: [Comment] = []
  @Published private(set) var submissions: [Post] = []

  private let log = OSLog(subsystem: "com.flayware.IllithidUI.accounts", category: .pointsOfInterest)

  init(account: Account?) {
    self.account = account
    if let account = account { loadAccount(account) }
  }

  convenience init(name: String) {
    self.init(account: nil)
    Account.fetch(username: name) { result in
      switch result {
      case let .success(account):
        self.account = account
        self.loadAccount(account)
      case let .failure(error):
        self.account = nil
        Illithid.shared.logger.errorMessage("Failure fetching account: \(error)")
      }
    }
  }

  /// Shortcut implementation while working on the view
  fileprivate func loadAccount(_ account: Account) {
    let overviewId = OSSignpostID(log: log)
    let commentsId = OSSignpostID(log: log)
    let submissionsId = OSSignpostID(log: log)

    os_signpost(.begin, log: log, name: "Load Overview", signpostID: overviewId, "%{public}s", account.name)
    account.overview { result in
      switch result {
      case let .success(listing):
        self.overview.append(contentsOf: listing.children)
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch overview: \(error)")
      }
      os_signpost(.end, log: self.log, name: "Load Overview", signpostID: overviewId, "%{public}s", account.name)
    }

    account.savedContent { result in
      switch result {
      case let .success(listing):
        self.saved.append(contentsOf: listing.children)
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch saved content: \(error)")
      }
    }

    account.hiddenPosts { result in
      switch result {
      case let .success(posts):
        self.hidden.append(contentsOf: posts)
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch hidden posts: \(error)")
      }
    }

    account.upvotedPosts { result in
      switch result {
      case let .success(posts):
        self.upvoted.append(contentsOf: posts)
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch upvoted posts: \(error)")
      }
    }

    account.downvotedPosts { result in
      switch result {
      case let .success(posts):
        self.downvoted.append(contentsOf: posts)
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch downvoted posts: \(error)")
      }
    }

    os_signpost(.begin, log: log, name: "Load Comments", signpostID: commentsId, "%{public}s", account.name)
    account.comments { result in
      switch result {
      case let .success(comments):
        self.comments.append(contentsOf: comments)
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch comments: \(error)")
      }
      os_signpost(.end, log: self.log, name: "Load Comments", signpostID: commentsId, "%{public}s", account.name)
    }

    os_signpost(.begin, log: log, name: "Load Submissions", signpostID: submissionsId, "%{public}s", account.name)
    account.submissions { result in
      switch result {
      case let .success(posts):
        self.submissions.append(contentsOf: posts)
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch submissions: \(error)")
      }
      os_signpost(.end, log: self.log, name: "Load Submissions", signpostID: submissionsId, "%{public}s", account.name)
    }
  }
}
