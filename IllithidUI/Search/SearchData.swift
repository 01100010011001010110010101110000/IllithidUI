//
// SearchData.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class SearchData: ObservableObject {
  @Published var query: String = ""
  @Published var accounts: [Account] = []
  @Published var subreddits: [Subreddit] = []
  @Published var posts: [Post] = []

  private var results: Listing = .init()

  let illithid: Illithid = .shared
  private var cancelToken: AnyCancellable?

  init() {
    cancelToken = $query
      .filter { $0.count > 3 }
      .debounce(for: 0.3, scheduler: RunLoop.current)
      .removeDuplicates()
      .sink { searchFor in
        self.illithid.search(for: searchFor, queue: .global(qos: .userInteractive)) { result in
          switch result {
          case let .success(listings):
            DispatchQueue.main.async {
              self.accounts.removeAll(keepingCapacity: true)
              self.subreddits.removeAll(keepingCapacity: true)
              self.posts.removeAll(keepingCapacity: true)
              // TODO: Optimize this
              for listing in listings {
                self.accounts.append(contentsOf: listing.accounts)
                self.subreddits.append(contentsOf: listing.subreddits)
                self.posts.append(contentsOf: listing.posts)
              }
            }
          case let .failure(error):
            print("Failed to search: \(error)")
          }
        }
      }
  }
}
