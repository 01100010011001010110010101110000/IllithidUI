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
  var root = Node<CommentWrapper>()

  let post: Post

  private let illithid: Illithid = .shared
  private var cancelToken: AnyCancellable?
  private var moreCancelToken: AnyCancellable?
  private let log = OSLog(subsystem: "com.illithid.IllithidUI.Comments",
                          category: .pointsOfInterest)

  init(post: Post) {
    self.post = post
  }

  init(from listing: Listing) {
    post = listing.posts.first!
    let unsortedComments = listing.allComments
    comments.reserveCapacity(unsortedComments.capacity)
    unsortedComments.forEach { comment in
      self.preOrder(node: comment) { wrapper in
        self.comments.append(wrapper)
        self.showComment[comment.id] = .expanded
      }
    }
  }

  // MARK: Tree functions

  /// Performs a pre-order depth first search on the comment tree
  ///
  /// Traverses the tree, executing `body` on a node before visiting its children
  /// - Parameter node: The root comment to traverse
  /// - Parameter visitChildren: A closure which will prevent traversal of a node's children if `false`
  /// - Parameter body: The closure to execute on each comment
  /// - Complexity: `O(n)` where `n` is the number of comments in the tree
  func preOrder(node: CommentWrapper,
                visitChildren: (CommentWrapper) -> Bool = { _ in true },
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
                 visitChildren: (CommentWrapper) -> Bool = { _ in true },
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

  // MARK: Comment loading

  func loadComments() {
    cancelToken = illithid.comments(for: post, parameters: listingParameters)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { value in
        self.illithid.logger.errorMessage("Error fetching comments\(value)")
      }) { listing in
        // Append the top level comments
        self.root.append(contentsOf: listing.allComments)

        // Recursively insert replies into the tree by fetching them from the initial nodes
        // Each layer of nodes populated into the tree adds more nodes to traverse, fetching additional replies until
        //   we are at leaf comments
        self.root.traverse(preOrder: { node in
          if let value = node.value {
            if case let CommentWrapper.comment(comment) = value {
              node.append(contentsOf: comment.replies?.allComments ?? [])
            }
            self.showComment[value.id] = .expanded
            self.comments.append(value)
          }
        })
      }
  }

  func loadMoreComments(more: More) {
    moreCancelToken = illithid.moreComments(for: more, in: post)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { value in
        self.illithid.logger.errorMessage("Error fetching more comments\(value)")
    }) { wrappers in
        // Remove More object from tree
        self.root.removeSubtree { node in
          node.value?.id == more.id
        }
        wrappers.forEach { wrapper in
          // Insert fetched comments into the tree
          self.showComment[wrapper.id] = .expanded
          if wrapper.parentId == self.post.fullname {
            self.root.append(child: wrapper)
          } else {
            self.root.insert(wrapper, firstWhere: { node in
              guard let value = node.value else { return false }
              if case let CommentWrapper.comment(parent) = value {
                return wrapper.parentId == parent.fullname
              }
              return false
          })
          }
        }

        // Update comments with the new tree, flattened into an array in the approrpiate order
        var newComments: [CommentWrapper] = []
        self.root.traverse(preOrder: { node in
          guard let value = node.value else { return }
          newComments.append(value)
      })
        self.comments = newComments
      }
  }
}

// MARK: Tree structure

class Node<Element> {
  let value: Element?
  var children: [Node<Element>]
  let parent: Node<Element>?

  init(value: Element? = nil, children: [Node<Element>] = [], parent: Node<Element>? = nil) {
    self.value = value
    self.children = children
    self.parent = parent
  }

  func append(child: Element) {
    children.append(Node(value: child, parent: self))
  }

  func append(contentsOf: [Element]) {
    children.append(contentsOf: contentsOf.map { Node(value: $0, parent: self) })
  }

  func first(where body: (Node<Element>) -> Bool) -> Node<Element>? {
    var result: Node<Element>?
    traverse(preOrder: { node in
      if body(node) { result = node }
    })
    return result
  }

  func insert(_ newElement: Element, firstWhere: (Node<Element>) -> Bool) {
    traverse(preOrder: { node in
      if firstWhere(node) { node.append(child: newElement) }
    })
  }

  func removeSubtree(firstWhere: (Node<Element>) -> Bool) {
    if let index = children.firstIndex(where: { firstWhere($0) }) {
      children.remove(at: index)
    } else {
      children.forEach { child in
        child.traverse(preOrder: { node in
          if let index = node.children.firstIndex(where: { firstWhere($0) }) {
            node.children.remove(at: index)
          }
        })
      }
    }
  }

  func traverse(preOrder: (Node<Element>) -> Void = { _ in }, postOrder: (Node<Element>) -> Void = { _ in },
                visitChildren: (Node<Element>) -> Bool = { _ in true }) {
    preOrder(self)
    if visitChildren(self) {
      children.forEach { child in
        child.traverse(preOrder: preOrder, postOrder: postOrder, visitChildren: visitChildren)
      }
    }
    postOrder(self)
  }
}

extension Node: Equatable where Element: Equatable {
  static func == (lhs: Node<Element>, rhs: Node<Element>) -> Bool {
    return lhs.children == rhs.children &&
      lhs.parent == rhs.parent &&
      lhs.value == rhs.value
  }

  func insert(at node: Node<Element>, newElement: Element) {
    traverse(preOrder: { subNode in
      if node == subNode { node.append(child: newElement) }
    })
  }
}
