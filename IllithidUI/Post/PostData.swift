//
// PostData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import os.log
import SwiftUI

import Illithid

final class PostData<PostContainer: PostsProvider>: ObservableObject {
  @Published var posts: [Post] = []
  @Published var sort: PostSort = .best {
    willSet {
      posts.removeAll(keepingCapacity: true)
      postListingParams = .init()
    }
    didSet {
      loadPosts()
    }
  }

  private let postsProvider: PostsProvider
  private var postListingParams: ListingParameters = .init()
  private let illithid: Illithid = .shared
  private let log = OSLog(subsystem: "com.illithid.IllithidUI.Posts",
                          category: .pointsOfInterest)

  init(provider: PostsProvider) {
    postsProvider = provider
  }

  func loadPosts() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Posts", signpostID: signpostId)
    postsProvider.posts(sortBy: sort, parameters: postListingParams, queue: .global(qos: .userInteractive)) { result in
      switch result {
      case let .success(listing):
        if let anchor = listing.after { self.postListingParams.after = anchor }
        DispatchQueue.main.async {
          self.posts.append(contentsOf: listing.posts)
        }
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to load posts: \(error)")
      }
      os_signpost(.end, log: self.log, name: "Load Posts", signpostID: signpostId)
    }
  }
}
