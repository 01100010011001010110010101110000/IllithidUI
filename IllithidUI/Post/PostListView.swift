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
  @ObservedObject var postsData: PostData<PostContainer>
  @State private var searchText: String = ""

  let postContainer: PostContainer
  let commentsManager: WindowManager = WindowManager<CommentsView>()
  let debugManager: WindowManager = WindowManager<PostDebugView>()

  private let cancelToken: AnyCancellable? = nil

  init(postContainer: PostContainer) {
    self.postContainer = postContainer
    self.postsData = PostData(provider: self.postContainer)
  }

  var body: some View {
    VStack {
      HStack {
        Picker(selection: $postsData.sort, label: EmptyView()) {
          ForEach(PostSort.allCases) { sortMethod in
            Text(sortMethod.rawValue).tag(sortMethod)
          }
        }
        Spacer()
      }
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
              self.postsData.loadPosts()
            })
        }
      }
      .onAppear {
        self.postsData.loadPosts()
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
