//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import Combine
import os.log
import SwiftUI

import Illithid

final class PostData: ObservableObject {
  @Published var posts: [Post] = []

  private var postListingParams: ListingParameters = .init()
  private let illithid: Illithid = .shared
  private let log = OSLog(subsystem: "com.illithid.IllithidUI.Posts",
                          category: .pointsOfInterest)

  func loadPosts(container: PostsProvider) {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Posts", signpostID: signpostId)
    container.posts(sortBy: .hot, parameters: postListingParams, queue: .global(qos: .userInteractive)) { result in
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
