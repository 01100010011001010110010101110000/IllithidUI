//
// PostListView.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation
import SwiftUI

import Illithid

struct PostListView<PostContainer: PostsProvider>: View {
  @ObservedObject var postsData: PostData
  @State private var postListingParams: ListingParameters = .init()

  let illithid: Illithid = .shared
  let postContainer: PostContainer
  let commentsManager: WindowManager = WindowManager<CommentsView>()
  let debugManager: WindowManager = WindowManager<PostDebugView>()

  init(postsData: PostData = .init(), postContainer: PostContainer) {
    self.postContainer = postContainer
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
          .contextMenu {
            Button(action: {
              self.showComments(for: post)
            }) {
              Text("Show comments…")
            }
            Divider()
            Button(action: {
              NSWorkspace.shared.open(post.postUrl)
            }) {
              Text("Open post in browser…")
            }
            Button(action: {
              NSWorkspace.shared.open(post.contentUrl)
            }) {
              Text("Open content in browser…")
            }
            Divider()
            Button(action: {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(post.postUrl.absoluteString, forType: .string)
            }) {
              Text("Copy post URL")
            }
            Button(action: {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(post.contentUrl.absoluteString, forType: .string)
            }) {
              Text("Copy content URL")
            }
            Divider()
            Button(action: {
              self.showDebugWindow(for: post)
            }) {
              Text("Show debug panel…")
            }
          }
      }
    }
    .frame(minWidth: 450, idealWidth: 600, maxWidth: 800)
    .onAppear {
      self.loadPosts()
    }
  }

  func loadPosts() {
    postContainer.posts(sortBy: .hot, parameters: postListingParams) { result in
      switch result {
      case let .success(listing):
        if let anchor = listing.after { self.postListingParams.after = anchor }
        self.postsData.posts.append(contentsOf: listing.posts)
      case let .failure(error):
        return
      }
    }
  }

  func showComments(for post: Post) {
    commentsManager.showWindow(for: CommentsView(post: post), title: post.title)
  }

  func showDebugWindow(for post: Post) {
    debugManager.showWindow(for: PostDebugView(post: post), title: "\(post.title) - Debug View")
  }
}

// #if DEBUG
// struct PostListView_Previews: PreviewProvider {
//  static var previews: some View {
//    PostListView(postsData: .init(), subreddit: .init(), reddit: .init())
//  }
// }
// #endif
