//
// PostListData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import Combine
import os.log
import SwiftUI

import Alamofire
import Illithid

final class PostListData: ObservableObject {
  @Published var posts: [Post] = []
  @Published var sort: PostSort = .best {
    didSet {
      posts.removeAll(keepingCapacity: true)
      postListingParams = .init()
      loadPosts()
    }
  }

  @Published var topInterval: TopInterval = .day {
    didSet {
      posts.removeAll(keepingCapacity: true)
      postListingParams = .init()
      loadPosts()
    }
  }

  let postsProvider: PostProvider

  private var postListingParams: ListingParameters = .init()
  private var exhausted: Bool = false
  private let illithid: Illithid = .shared
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.posts",
                          category: .pointsOfInterest)
  private var requests: [DataRequest] = []

  init(provider: PostProvider) {
    postsProvider = provider
  }

  func loadPosts() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Posts", signpostID: signpostId)
    if !exhausted {
      let request = postsProvider.posts(sortBy: sort, location: nil, topInterval: topInterval,
                                        parameters: postListingParams, queue: .main) { result in
        switch result {
        case let .success(listing):
          if let anchor = listing.after { self.postListingParams.after = anchor }
          else { self.exhausted = true }
          self.posts.append(contentsOf: listing.posts)
        case let .failure(error):
          self.illithid.logger.errorMessage("Failed to load posts: \(error)")
        }
        os_signpost(.end, log: self.log, name: "Load Posts", signpostID: signpostId)
      }
      requests.append(request)
    }
  }

  func cancel() {
    while !requests.isEmpty {
      requests.popLast()?.cancel()
    }
  }
}
