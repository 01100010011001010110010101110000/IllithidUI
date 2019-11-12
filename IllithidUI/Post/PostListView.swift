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

import AlamofireImage
import Illithid
import Willow

struct PostListView: View {
  @ObservedObject var postsData: PostData
  @State private var postListingParams: ListingParameters = .init()

  let illithid: Illithid = .shared
  let subreddit: Subreddit
  let commentsManager: WindowManager = WindowManager<CommentsView>()

  init(postsData: PostData, subreddit: Subreddit) {
    self.subreddit = subreddit
    self.postsData = postsData
  }

  var body: some View {
    List {
      ForEach(self.postsData.posts) { post in
        PostRowView(post: post)
          .conditionalModifier(post == self.postsData.posts.last, OnAppearModifier {
            self.loadPosts()
          })
          .onTapGesture(count: 2) {
            self.showComments(for: post)
          }
      }
    }
    .onAppear {
      self.loadPosts()
    }
  }

  func loadPosts() {
    illithid.fetchPosts(for: subreddit, sortBy: .hot, params: postListingParams) { listing in
      if let anchor = listing.after { self.postListingParams.after = anchor }
      self.postsData.posts.append(contentsOf: listing.posts)
    }
  }

  func showComments(for post: Post) {
    commentsManager.showWindow(for: CommentsView(commentData: .init(), post: post), title: post.title)
  }
}

extension HorizontalAlignment {
  private enum MidStatsAndPreview: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat {
      d[HorizontalAlignment.center]
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
