// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

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

  @Published private(set) var comments: [Comment] = []
  /// The root-level more object, representing additional top-level comments on `post`
  @Published private(set) var rootMore: More? = nil

  let post: Post
  private let illithid: Illithid = .shared
  private var cancelToken: AnyCancellable?
  private var moreCancelToken: AnyCancellable?
  private var listingParameters = ListingParameters(limit: 100)
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.comments",
                          category: .pointsOfInterest)

  init(post: Post) {
    self.post = post
  }

  init(from listing: Listing) {
    post = listing.posts.first!
    comments = listing.comments
  }

  // MARK: Comment loading

  func loadComments(focusOn commentId: ID36? = nil, context: Int? = nil) {
    cancelToken = illithid.comments(for: post, parameters: listingParameters, focusOn: commentId, context: context)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          Illithid.shared.logger.debugMessage("Finished fetching comments for \(self.post.name) - \(self.post.title)")
        case let .failure(error):
          self.illithid.logger.errorMessage("Error fetching comments \(error)")
        }
      }) { listing in
        self.comments.append(contentsOf: listing.comments)
        self.rootMore = listing.more
      }
  }

  func cancel() {
    cancelToken?.cancel()
  }

  // For a flat array of comments, assemble all child comments
  // TODO: This can probably be optimized if the More reply is sorted.
  private func graftReplies(_ comments: [Comment]) -> [Comment] {
    var results: [Comment] = []
    var replies: Set<Fullname> = []

    for entry in comments {
      if replies.contains(entry.name) { continue }
      var comment = entry
      for nested in comments {
        if nested.parentId == comment.name {
          if comment.replies == nil { comment.replies = [nested] }
          else { comment.replies!.append(nested) }
          replies.insert(nested.name)
        }
      }
      results.append(comment)
    }
    return results
  }

  func expandMore(more: More) {
    moreCancelToken = illithid.moreComments(for: more, on: post)
      .sink(receiveCompletion: { [weak self] completion in
        guard let self = self else { return }
        switch completion {
        case .finished:
          Illithid.shared.logger.debugMessage("Finished fetching more comments for \(self.post.name) - \(self.post.title)")
        case let .failure(error):
          self.illithid.logger.errorMessage("Error fetching more comments \(error)")
        }
      }, receiveValue: { tuple in
        let replies = self.graftReplies(tuple.comments)
        if self.rootMore == more {
          self.comments.append(contentsOf: replies)
          self.rootMore = tuple.more
        }

        for idx in self.comments.indices {
          self.insertMoreReplies(starting: &self.comments[idx], commentId: more.parentId, with: (replies, tuple.more))
        }
      })
  }

  private func insertMoreReplies(starting: inout Comment, commentId: Fullname,
                                 with tuple: (comments: [Comment], more: More?)) {
    if starting.fullname == commentId {
      starting.update(tuple: tuple)
    }

    guard starting.replies != nil else { return }

    for idx in starting.replies!.indices {
      if starting.replies![idx].fullname == commentId {
        starting.replies![idx].update(tuple: tuple)
      } else {
        insertMoreReplies(starting: &starting.replies![idx], commentId: commentId, with: tuple)
      }
    }
  }
}

private extension Comment {
  func preOrder(_ task: (Comment) -> Void) {
    task(self)
    guard let children = replies else { return }
    for child in children {
      child.preOrder(task)
    }
  }

  mutating func update(tuple: (comments: [Comment], more: More?)) {
    var moreComments = tuple.comments

    if let more = tuple.more {
      if more.parentId == fullname {
        self.more = more
      } else if let idx = moreComments.firstIndex(where: { $0.fullname == more.parentId }) {
        moreComments[idx].more = more
        self.more = nil
      }
    } else {
      more = nil
    }

    if replies != nil {
      replies?.append(contentsOf: moreComments)
    } else {
      replies = moreComments
    }
  }
}
