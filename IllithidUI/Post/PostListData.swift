//
// PostListData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import Combine
import os.log
import SwiftUI

import Alamofire
import Illithid

final class PostListData: ObservableObject {
  @Published var posts: [Post] = []

  let provider: PostProvider

  init(provider: PostProvider) {
    self.provider = provider
  }

  private var postListingParams: ListingParameters = .init()
  private var exhausted: Bool = false
  private var loading: Bool = false
  private let illithid: Illithid = .shared
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.posts",
                          category: .pointsOfInterest)
  private var requests: [DataRequest] = []

  func loadPosts(sort: PostSort, topInterval: TopInterval) {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Posts", signpostID: signpostId)
    if !exhausted, !loading {
      loading = true
      let request = provider.posts(sortBy: sort, location: nil, topInterval: topInterval,
                                   parameters: postListingParams, queue: .main) { result in
        switch result {
        case let .success(listing):
          if let anchor = listing.after { self.postListingParams.after = anchor }
          else { self.exhausted = true }
          self.posts.append(contentsOf: listing.posts)
        case let .failure(error):
          self.illithid.logger.errorMessage("Failed to load posts: \(error)")
        }
        self.loading = false
        os_signpost(.end, log: self.log, name: "Load Posts", signpostID: signpostId)
      }
      requests.append(request)
    }
  }

  func reload(sort: PostSort, topInterval: TopInterval) {
    cancel()
    exhausted = false
    posts.removeAll(keepingCapacity: true)
    postListingParams = .init()
    loadPosts(sort: sort, topInterval: topInterval)
  }

  func cancel() {
    while !requests.isEmpty {
      requests.popLast()?.cancel()
    }
  }
}
