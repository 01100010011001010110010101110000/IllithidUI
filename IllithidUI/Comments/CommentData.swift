//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import Combine
import os.log
import SwiftUI

import Illithid

class CommentData: ObservableObject {
  @Published var comments: [Comment] = []
  @State private var listingParameters = ListingParameters(limit: 100)

  let post: Post

  private let illithid: Illithid = .shared
  private var cancelToken: AnyCancellable?
  private let log = OSLog(subsystem: "com.illithid.IllithidUI.Comments",
                          category: .pointsOfInterest)

  init(post: Post) {
    self.post = post
  }

  /// Performs a pre-order depth first search on the comment tree
  ///
  /// Performing a pre-order DFS on the comment tree has the effect of flattening the tree into an array while preserving the comment order,
  /// i.e. given an index in `results`, the successor is one of:
  /// *
  /// - Parameter node: The root comment to traverse
  /// - Parameter results: The array in which to place comment nodes
  /// - Complexity: `O(n)` where `n` is the number of comments in the tree
  fileprivate func preOrder(node: Comment, into results: inout [Comment]) {
    results.append(node)
    if let replies = node.replies?.comments, !replies.isEmpty {
      replies.forEach { comment in
        preOrder(node: comment, into: &results)
      }
    }
  }

  var allComments: [Comment] {
    let id = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Traverse Comments", signpostID: id, "%{public}s", post.title)
    var preOrderComments: [Comment] = []
    preOrderComments.reserveCapacity(100)
    comments.forEach { comment in
      preOrder(node: comment, into: &preOrderComments)
    }
    os_signpost(.end, log: log, name: "Traverse Comments", signpostID: id, "%{public}s", post.title)
    return preOrderComments
  }

  func loadComments() {
    let id = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Comments", signpostID: id, "%{public}s", post.title)
    cancelToken = illithid.comments(for: post, parameters: listingParameters, queue: .global(qos: .userInteractive))
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { value in
        print("Error fetching comments\(value)")
      }) { listing in
        self.comments.append(contentsOf: listing.comments)
        os_signpost(.end, log: self.log, name: "Load Comments", signpostID: id, "%{public}s", self.post.title)
      }
  }
}
