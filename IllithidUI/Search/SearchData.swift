//
//  SearchData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 7/8/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class SearchData: ObservableObject {
  @Published var query: String = ""
  @Published var accounts: [RedditAccount] = []
  @Published var subreddits: [Subreddit] = []
  @Published var posts: [Post] = []

  private var results: Listing = .init()

  let reddit: Illithid
  private var cancelToken: AnyCancellable? = nil

  init(reddit: Illithid) {
    self.reddit = reddit

    cancelToken = $query
      .filter { $0.count > 3 }
      .debounce(for: 0.3, scheduler: RunLoop.current)
      .removeDuplicates()
      .sink { searchFor in
        reddit.search(for: searchFor) { result in
          switch(result) {
          case .success(let listings):
            // TODO: Optimize this
            for listing in listings {
              self.accounts.append(contentsOf: listing.accounts)
              self.subreddits.append(contentsOf: listing.subreddits)
              self.posts.append(contentsOf: listing.posts)
            }
          case .failure(let error):
            print("Failed to search: \(error)")
          }
        }
    }
  }
}
