//
//  PostListView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/9/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

import Illithid
import Willow

struct PostListView: View {
  @ObjectBinding var postsData: PostData
  @State var postListingParams: ListingParams = .init()

  let subreddit: Subreddit
  let reddit: RedditClientBroker
  let commentsManager: CommentsWindowManager

  init(postsData: PostData, subreddit: Subreddit, reddit: RedditClientBroker) {
    self.subreddit = subreddit
    self.reddit = reddit
    self.postsData = postsData
    commentsManager = CommentsWindowManager(reddit: reddit)
  }

  var body: some View {
    List {
      ForEach(self.postsData.posts) { post in
        PostRowView(post: post, reddit: self.reddit)
          .tapAction(count: 2) {
            self.showComments(for: post)
        }
      }
    }
    .onAppear {
      self.loadPosts()
    }
  }

  func loadPosts() {
    self.reddit.fetchPosts(for: self.subreddit, sortBy: .hot, params: self.postListingParams) { listing in
      if let anchor = listing.metadata.after { self.postListingParams.after = anchor }
      listing.metadata.children.forEach { post in
        self.postsData.posts.append(post.object)
      }
    }
  }

  func showComments(for post: Post) {
    commentsManager.showWindow(for: post)
  }
}

extension HorizontalAlignment {
  private enum MidStatsAndPreview: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> Length {
      return d[HorizontalAlignment.center]
    }
  }

  static let midStatsAndPreview = HorizontalAlignment(MidStatsAndPreview.self)
}

// #if DEBUG
// struct PostListView_Previews: PreviewProvider {
//  static var previews: some View {
//    PostListView(postsData: .init(), subreddit: .init(), reddit: .init())
//  }
// }
// #endif
