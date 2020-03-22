//
// SubredditListData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import Combine
import Foundation
import os.log

import Illithid

final class SubredditListData: ObservableObject {
  @Published var subreddits: [Subreddit] = []

  let illithid: Illithid = .shared
  private var listingParams: ListingParameters = .init()
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.subreddits",
                          category: .pointsOfInterest)

  func loadSubreddits() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Subreddits", signpostID: signpostId)
    illithid.subreddits(params: listingParams) { result in
      switch result {
      case let .success(listing):
        if let anchor = listing.after { self.listingParams.after = anchor }
        self.subreddits.append(contentsOf: listing.subreddits)
        os_signpost(.end, log: self.log, name: "Load Subreddits")
      case let .failure(error):
        self.illithid.logger.errorMessage("Error fetching subreddit data: \(error)")
      }
    }
  }
}
