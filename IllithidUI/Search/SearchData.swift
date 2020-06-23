//
// SearchData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
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
  @Published var suggestions: [Subreddit] = []

  let illithid: Illithid = .shared
  let searchTargets: Set<SearchType>

  private var cancelBag: [AnyCancellable] = []
  private var request: DataRequest?
  private var autocompleteRequest: DataRequest?

  var postContainers: [String: PostListData] = [:]

  init(for targets: Set<SearchType> = [.subreddit, .post, .user]) {
    searchTargets = targets
    let queryPublisher = $query.share()
//    let searchToken = queryPublisher
//      .filter { $0.count >= 3 }
//      .debounce(for: 0.3, scheduler: RunLoop.current)
//      .removeDuplicates()
//      .sink { [weak self] searchFor in
//        guard let self = self else { return }
//        self.request?.cancel()
//        self.request = self.search(for: searchFor)
//      }
    let autocompleteToken = queryPublisher
      .debounce(for: 0.2, scheduler: RunLoop.main)
      .removeDuplicates()
      .sink { [weak self] toComplete in
        guard let self = self else { return }
        self.autocompleteRequest?.cancel()
        self.autocompleteRequest = self.illithid.completeSubreddits(startsWith: toComplete, limit: 10) { result in
          switch result {
          case let .success(subreddits):
            self.suggestions = subreddits
          case let .failure(error):
            self.illithid.logger.errorMessage("Unable to autocomplete query: \(error)")
          }
        }
      }
    cancelBag.append(autocompleteToken)
//    cancelBag.append(searchToken)
  }

  deinit {
    autocompleteRequest?.cancel()
    request?.cancel()
    cancelBag.cancel()
  }

  func search(for searchText: String) -> DataRequest {
    illithid.search(for: searchText, resultTypes: searchTargets) { result in
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

  func postContainer(for provider: PostProvider) -> PostListData {
    if let container = postContainers[provider.id] { return container }
    else {
      let container = PostListData(provider: provider)
      postContainers[provider.id] = container
      return container
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
