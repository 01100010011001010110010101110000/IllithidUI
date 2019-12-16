//
//  MultiredditListView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/21/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct MultiredditListView: View {
  @ObservedObject var postsData: PostData
  @State private var postListingParams: ListingParameters = .init()

  let illithid: Illithid = .shared
  let multireddit: Multireddit
  let commentsManager: WindowManager = WindowManager<CommentsView>()

  init(multireddit: Multireddit, postsData: PostData = .init()) {
    self.multireddit = multireddit
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
    illithid.fetchPosts(for: multireddit, sortBy: .hot, params: postListingParams) { listing in
      if let anchor = listing.after { self.postListingParams.after = anchor }
      self.postsData.posts.append(contentsOf: listing.posts)
    }
  }

  func showComments(for post: Post) {
    commentsManager.showWindow(for: CommentsView(post: post), title: post.title)
  }
}

//struct MultiredditListView_Previews: PreviewProvider {
//  static var previews: some View {
//    MultiredditListView()
//  }
//}
