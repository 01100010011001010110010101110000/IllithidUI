//
//  FrontPageListView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/24/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct FrontPageListView: View {
  @ObservedObject var postsData: PostData = .init()
  @State private var postListingParams: ListingParameters = .init()

  let illithid: Illithid = .shared
  let page: FrontPage
  let commentsManager: WindowManager = WindowManager<CommentsView>()

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
    illithid.fetchPosts(for: page, sortBy: .hot, params: postListingParams) { listing in
      if let anchor = listing.after { self.postListingParams.after = anchor }
      self.postsData.posts.append(contentsOf: listing.posts)
    }
  }

  func showComments(for post: Post) {
    commentsManager.showWindow(for: CommentsView(post: post), title: post.title)
  }
}

// struct FrontPageListView_Previews: PreviewProvider {
//    static var previews: some View {
//        FrontPageListView()
//    }
// }
