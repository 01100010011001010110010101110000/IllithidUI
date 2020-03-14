//
// SearchData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation
import SwiftUI

import Alamofire
import Illithid

final class SearchData: ObservableObject {
  @Published var query: String = ""
  @Published var accounts: [Account] = []
  @Published var subreddits: [Subreddit] = []
  @Published var posts: [Post] = []

  let illithid: Illithid = .shared
  let searchTargets: Set<SearchType>
  private var cancelToken: AnyCancellable?
  private var request: DataRequest?

  init(for targets: Set<SearchType> = [.subreddit, .post, .user]) {
    searchTargets = targets
    cancelToken = $query
      .filter { $0.count >= 3 }
      .debounce(for: 0.3, scheduler: RunLoop.current)
      .removeDuplicates()
      .sink { [weak self] searchFor in
        guard let self = self else { return }
        self.request?.cancel()
        self.request = self.search(for: searchFor)
      }
  }

  deinit {
    cancelToken?.cancel()
  }

  // TODO: Cancel inflight searches if another is started
  func search(for searchText: String) -> DataRequest {
    return illithid.search(for: searchText, resultTypes: searchTargets) { result in
      switch result {
      case let .success(listings):
        self.clearData()
        // TODO: Optimize this
        for listing in listings {
          self.accounts.append(contentsOf: listing.accounts)
          self.subreddits.append(contentsOf: listing.subreddits)
          self.posts.append(contentsOf: listing.posts)
        }
      case let .failure(error):
        self.illithid.logger.errorMessage("Failed to search: \(error)")
      }
    }
  }

  func clearData() {
    accounts.removeAll(keepingCapacity: true)
    subreddits.removeAll(keepingCapacity: true)
    posts.removeAll(keepingCapacity: true)
  }

  func clearQueryText() {
    query.removeAll()
  }
}
