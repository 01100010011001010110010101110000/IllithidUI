//
//  CommentData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/21/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import Illithid

class CommentData: ObservableObject {
  @Published var comments: [Comment] = []

  convenience init(from listing: Listing) {
    self.init()
    comments = listing.comments
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
    var preOrderComments: [Comment] = []
    preOrderComments.reserveCapacity(100)
    comments.forEach { comment in
      preOrder(node: comment, into: &preOrderComments)
    }
    return preOrderComments
  }
}
