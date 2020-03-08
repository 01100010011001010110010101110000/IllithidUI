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

struct PostListView: View {
  @ObservedObject var preferences: PreferencesData = .shared
  @ObservedObject var postsData: PostListData
  @State private var searchText: String = ""
  @State private var showSidebar: Bool = false

  let postContainer: PostProvider

  private let cancelToken: AnyCancellable? = nil

  private var filteredPosts: [Post] {
    return postsData.posts.filter { post in
      if preferences.hideNsfw, post.over18 {
        return false
      }
      if !searchText.isEmpty {
        return post.author.range(of: searchText, options: .caseInsensitive) != nil ||
          post.title.range(of: searchText, options: .caseInsensitive) != nil ||
          post.subreddit.range(of: searchText, options: .caseInsensitive) != nil ||
          post.selftext.range(of: searchText, options: .caseInsensitive) != nil
      }
      return true
    }
  }

  init(postContainer: PostProvider) {
    self.postContainer = postContainer
    postsData = PostListData(provider: self.postContainer)
  }

  init(data: PostListData) {
    self.postsData = data
    self.postContainer = data.postsProvider
  }

  var body: some View {
    VStack(spacing: 0.0) {
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
        .padding([.top, .leading, .trailing], 10)
        HStack {
          TextField("Search Posts", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
          if postContainer is Subreddit {
            Button("Sidebar") {
              withAnimation {
                self.showSidebar.toggle()
              }
            }
          }
        }
        .padding([.bottom, .leading, .trailing], 10)
      }
      .background(Color(.controlBackgroundColor))
      HSplitView {
        List {
          ForEach(filteredPosts) { post in
            PostRowView(post: post)
              .conditionalModifier(post == self.filteredPosts.last, OnAppearModifier {
                self.postsData.loadPosts()
              })
          }
        }
        .onAppear {
          self.postsData.loadPosts()
        }
        .onDisappear {
          self.postsData.cancel()
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
  @State private var subscribed: Bool = false
  let subreddit: Subreddit

  var body: some View {
    VStack {
      HStack {
        if subreddit.headerImg != nil {
          WebImage(url: subreddit.headerImg!)
        }
        Text(subreddit.displayName)
          .font(.largeTitle)
      }
      Divider()
      HStack {
        RoundedRectangle(cornerRadius: 2.0)
          .foregroundColor(subscribed ? .blue : Color(.darkGray))
          .overlay(Text("Subscribe"), alignment: .center)
          .foregroundColor(.white)
          .onTapGesture {
            if self.subscribed {
              self.subreddit.unsubscribe { result in
                if case Result.success = result {
                  self.subscribed = false
                }
              }
            } else {
              self.subreddit.subscribe { result in
                if case Result.success = result {
                  self.subscribed = true
                }
              }
            }
          }
          .frame(width: 32, height: 32)
          .padding(.leading, 10)
        Spacer()
      }
      Divider()
      ScrollView {
        Text(subreddit.description ?? "")
      }
    }
    .onAppear {
      self.subscribed = self.subreddit.userIsSubscriber ?? false
    }
  }
}

/// Loads a PostListView when we have only a subreddit name
struct SubredditLoader: View, Identifiable {
  @State private var subreddit: Subreddit?

  let subredditFullname: Fullname

  var id: String { subredditFullname }

  init(fullname subredditFullname: Fullname) {
    self.subredditFullname = subredditFullname
  }

  var body: some View {
    Group {
      if subreddit == nil {
        Rectangle()
          .opacity(0.0)
          .onAppear {
            Subreddit.fetch(name: self.subredditFullname) { result in
              switch result {
              case let .success(subreddit):
                self.subreddit = subreddit
              case let .failure(error):
                Illithid.shared.logger.errorMessage("Error loading subreddit: \(error)")
              }
            }
          }
      } else {
        subreddit.map { toDisplay in
          PostListView(postContainer: toDisplay)
        }
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
