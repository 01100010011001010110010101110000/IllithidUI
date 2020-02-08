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
  @Published var showComment: [ID36: Bool] = [:]
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

  init(from listing: Listing) {
    self.post = listing.posts.first!
    let unsortedComments = listing.allComments
    self.comments.reserveCapacity(unsortedComments.capacity)
    unsortedComments.forEach { comment in
      self.preOrder(node: comment) { wrapper in
        self.comments.append(wrapper)
        self.showComment[comment.id] = true
      }
    }
  }

  /// Performs a pre-order depth first search on the comment tree
  ///
  /// Traverses the tree, executing `body` on a node before visiting its children
  /// - Parameter node: The root comment to traverse
  /// - Parameter body: The closure to execute on each comment
  /// - Complexity: `O(n)` where `n` is the number of comments in the tree
  func preOrder(node: CommentWrapper, body: (CommentWrapper) -> Void) {
    body(node)
    if case let CommentWrapper.comment(comment) = node {
      if let replies = comment.replies, !replies.isEmpty {
        replies.allComments.forEach { comment in
          preOrder(node: comment) { body($0) }
        }
      }
    }
  }

  /// Performs a post-order depth first search on the comment tree
  ///
  /// Traverses the tree, executing `body` on a node only when it has no children or all its children
  /// have been visited
  /// - Parameter node: The root comment to traverse
  /// - Parameter body: The closure to execute on each comment
  /// - Complexity: `O(n)` where `n` is the number of comments in the tree
  func postOrder(node: CommentWrapper, body: (CommentWrapper) -> Void) {
    if case let CommentWrapper.comment(comment) = node {
      if let replies = comment.replies, !replies.isEmpty {
        replies.allComments.forEach { node in
          postOrder(node: node) { body($0) }
        }
      }
    }
    body(node)
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
          self.showComment[comment.id] = true
          self.preOrder(node: comment) { wrapper in
            self.comments.append(wrapper)
            self.showComment[wrapper.id] = true
          }
        }
        os_signpost(.end, log: self.log, name: "Traverse Comments", signpostID: id, "%{public}s", self.post.title)
        os_signpost(.end, log: self.log, name: "Load Comments", signpostID: id, "%{public}s", self.post.title)
      }
  }
}
