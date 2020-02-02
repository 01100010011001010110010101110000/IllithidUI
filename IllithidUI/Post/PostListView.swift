//
// PostListView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation
import SwiftUI

import Illithid

struct PostListView<PostContainer: PostsProvider>: View {
  @ObservedObject var postsData: PostData
  @State private var searchText: String = ""

  let postContainer: PostContainer
  let commentsManager: WindowManager = WindowManager<CommentsView>()
  let debugManager: WindowManager = WindowManager<PostDebugView>()

  init(postsData: PostData = .init(), postContainer: PostContainer) {
    self.postContainer = postContainer
    self.postsData = postsData
  }

  var body: some View {
    VStack {
      TextField("Search Posts", text: $searchText)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
      List {
        ForEach(self.postsData.posts.filter {
          $0.author.hasPrefix(searchText) || $0.title.hasPrefix(searchText) ||
            $0.subreddit.hasPrefix(searchText) || $0.selftext.contains(searchText)
        }) { post in
          PostRowView(post: post, commentsManager: self.commentsManager, debugManager: self.debugManager)
            .conditionalModifier(post == self.postsData.posts.last, OnAppearModifier {
              self.postsData.loadPosts(container: self.postContainer)
            })
        }
      }
      .onAppear {
        self.postsData.loadPosts(container: self.postContainer)
      }
    }
  }
}

// #if DEBUG
// struct PostListView_Previews: PreviewProvider {
//  static var previews: some View {
//    PostListView(postsData: .init(), subreddit: .init(), reddit: .init())
//  }
// }
// #endif
