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
  enum CollapseState {
    case expanded
    case parentCollapsed
    case collapsed
    case collapsedParentCollapsed
  }

  @Published var showComment: [ID36: CollapseState] = [:]
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
        self.showComment[comment.id] = .expanded
      }
    }
  }

  /// Performs a pre-order depth first search on the comment tree
  ///
  /// Traverses the tree, executing `body` on a node before visiting its children
  /// - Parameter node: The root comment to traverse
  /// - Parameter visitChildren: A closure which will prevent traversal of a node's children if `false`
  /// - Parameter body: The closure to execute on each comment
  /// - Complexity: `O(n)` where `n` is the number of comments in the tree
  func preOrder(node: CommentWrapper,
                visitChildren: (CommentWrapper) -> Bool = { _ in return true },
                body: (CommentWrapper) -> Void) {
    body(node)
    if case let CommentWrapper.comment(comment) = node {
      if let replies = comment.replies, !replies.isEmpty {
        if visitChildren(node) {
          replies.allComments.forEach { comment in
            preOrder(node: comment, visitChildren: visitChildren) { body($0) }
          }
        }
      }
    }
  }

  /// Performs a post-order depth first search on the comment tree
  ///
  /// Traverses the tree, executing `body` on a node only when it has no children or all its children
  /// have been visited
  /// - Parameter node: The root comment to traverse
  /// - Parameter visitChildren: A closure which will prevent traversal of a node's children if `false`
  /// - Parameter body: The closure to execute on each comment
  /// - Complexity: `O(n)` where `n` is the number of comments in the tree
  func postOrder(node: CommentWrapper,
                 visitChildren: (CommentWrapper) -> Bool = { _ in return true },
                 body: (CommentWrapper) -> Void) {
    if case let CommentWrapper.comment(comment) = node {
      if let replies = comment.replies, !replies.isEmpty {
        if visitChildren(node) {
          replies.allComments.forEach { node in
            postOrder(node: node, visitChildren: visitChildren) { body($0) }
          }
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
        self.comments.reserveCapacity(unsortedComments.count)
        unsortedComments.forEach { comment in
          self.preOrder(node: comment) { wrapper in
            self.comments.append(wrapper)
            self.showComment[wrapper.id] = .expanded
          }
        }
        os_signpost(.end, log: self.log, name: "Traverse Comments", signpostID: id, "%{public}s", self.post.title)
        os_signpost(.end, log: self.log, name: "Load Comments", signpostID: id, "%{public}s", self.post.title)
      }
  }
}
