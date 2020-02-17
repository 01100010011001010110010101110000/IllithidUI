//
// PostListView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation
import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct PostListView<PostContainer: PostsProvider>: View {
  @ObservedObject var postsData: PostData<PostContainer>
  @State private var searchText: String = ""
  @State private var showSidebar: Bool = false

  let postContainer: PostContainer
  let commentsManager: WindowManager = WindowManager<CommentsView>()
  let debugManager: WindowManager = WindowManager<PostDebugView>()

  private let cancelToken: AnyCancellable? = nil

  private var filteredPosts: [Post] {
    if searchText.isEmpty { return postsData.posts }
    return postsData.posts.filter {
      $0.author.range(of: searchText, options: .diacriticInsensitive) != nil ||
        $0.title.range(of: searchText, options: .diacriticInsensitive) != nil ||
        $0.subreddit.range(of: searchText, options: .diacriticInsensitive) != nil ||
        $0.selftext.range(of: searchText, options: .diacriticInsensitive) != nil
    }
  }

  init(postContainer: PostContainer) {
    self.postContainer = postContainer
    postsData = PostData(provider: self.postContainer)
  }

  var body: some View {
    VStack {
      HStack {
        Picker(selection: $postsData.sort, label: EmptyView()) {
          ForEach(PostSort.allCases) { sortMethod in
            Text(sortMethod.rawValue).tag(sortMethod)
          }
        }
        .frame(maxWidth: 100)
        if postsData.sort == .top || postsData.sort == .controversial {
          Picker(selection: $postsData.topInterval, label: EmptyView()) {
            ForEach(TopInterval.allCases) { interval in
              Text(interval.rawValue).tag(interval)
            }
          }
          .frame(maxWidth: 100)
        }
        Spacer()
      }
      .padding([.top, .leading])
      HStack {
        TextField("Search Posts", text: $searchText)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        Button("Sidebar") {
          withAnimation {
            self.showSidebar.toggle()
          }
        }
      }
      .padding([.bottom, .leading, .trailing])
      HSplitView {
        List {
          ForEach(filteredPosts) { post in
            PostRowView(post: post, commentsManager: self.commentsManager, debugManager: self.debugManager)
              .conditionalModifier(post == self.filteredPosts.last, OnAppearModifier {
                self.postsData.loadPosts()
                })
          }
        }
        .onAppear {
          self.postsData.loadPosts()
        }
        if postContainer is Subreddit && showSidebar {
          SidebarView(subreddit: postContainer as! Subreddit)
            .frame(minWidth: 200, maxWidth: 400)
        }
      }
    }
  }
}

struct SidebarView: View {
  let subreddit: Subreddit

  var body: some View {
    VStack {
      if subreddit.headerImg != nil {
        WebImage(url: subreddit.headerImg!)
      }
      ScrollView {
        Text(subreddit.description)
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
