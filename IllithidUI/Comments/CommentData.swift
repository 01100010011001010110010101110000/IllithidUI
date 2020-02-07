//
// CommentData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import os.log
import SwiftUI

import Illithid

class CommentData: ObservableObject {
  @Published private(set) var comments: [CommentWrapper] = []
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
  /// Performing a pre-order DFS on the comment tree has the effect of flattening the tree into an array while preserving the comment order
  /// - Parameter node: The root comment to traverse
  /// - Complexity: `O(n)` where `n` is the number of comments in the tree
  private func preOrder(node: CommentWrapper) {
    self.comments.append(node)
    if case let CommentWrapper.comment(comment) = node {
      if let replies = comment.replies, !replies.isEmpty {
        replies.allComments.forEach { comment in
          preOrder(node: comment)
        }
      }
    }
  }

  func loadComments() {
    let id = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Comments", signpostID: id, "%{public}s", post.title)
    cancelToken = illithid.comments(for: post, parameters: listingParameters, queue: .global(qos: .userInteractive))
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { value in
        self.illithid.logger.errorMessage("Error fetching comments\(value)")
      }) { listing in
        let id = OSSignpostID(log: self.log)
        os_signpost(.begin, log: self.log, name: "Traverse Comments", signpostID: id, "%{public}s", self.post.title)
        let unsortedComments = listing.allComments
        self.comments.reserveCapacity(unsortedComments.capacity)
        unsortedComments.forEach { comment in
          self.preOrder(node: comment)
        }
        os_signpost(.end, log: self.log, name: "Traverse Comments", signpostID: id, "%{public}s", self.post.title)
        os_signpost(.end, log: self.log, name: "Load Comments", signpostID: id, "%{public}s", self.post.title)
      }
  }
}
