//
// PostListView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/11/20
//

import Combine
import Foundation
import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct PostListView: View {
  @Environment(\.navigationLayout) var layout
  @EnvironmentObject var informationBarData: InformationBarData
  @ObservedObject var preferences: PreferencesData = .shared

  @State private var searchText: String = ""
  @State private var showSidebar: Bool = false
  @StateObject private var sorter = SortModel(sort: PostSort.best, topInterval: .day)
  @StateObject private var postsData: PostListData

  let postContainer: PostProvider

  private let cancelToken: AnyCancellable? = nil

  private var filteredPosts: [Post] {
    postsData.posts.filter { post in
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
    _postsData = .init(wrappedValue: .init(provider: postContainer))
  }

  var body: some View {
    VStack(spacing: 0.0) {
      VStack {
        SortController(model: sorter)
          .onReceive(sorter.$sort) { sort in
            guard !postsData.posts.isEmpty else { return }
            postsData.reload(sort: sort,
                             topInterval: sorter.topInterval)
          }
          .onReceive(sorter.$topInterval) { interval in
            guard !postsData.posts.isEmpty else { return }
            postsData.reload(sort: sorter.sort,
                             topInterval: interval)
          }
        HStack {
          TextField("Search Posts", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
          if postContainer is Subreddit {
            Button(action: {
              withAnimation {
                showSidebar.toggle()
              }
            }, label: {
              Image(systemName: "sidebar.right")
                .font(.body)
            })
          }
        }
        .padding([.bottom, .leading, .trailing], 10)
      }
      .background(Color(.controlBackgroundColor))

      HSplitView {
        switch layout {
        case .compact, .classic:
          ClassicListBody(posts: filteredPosts, onLastPost: {
            postsData.loadPosts(sort: sorter.sort,
                                topInterval: sorter.topInterval)
          })
            .loadingScreen(isLoading: postsData.posts.isEmpty, title: "Loading posts")
            .onAppear {
              // Do not load posts on a re-render
              guard postsData.posts.isEmpty else { return }
              postsData.loadPosts(sort: sorter.sort,
                                  topInterval: sorter.topInterval)
            }
            .onDisappear {
              postsData.cancel()
            }
        case .large:
          List {
            ForEach(filteredPosts) { post in
              PostRowView(post: post)
                .onAppear {
                  if post == filteredPosts.last {
                    postsData.loadPosts(sort: sorter.sort,
                                        topInterval: sorter.topInterval)
                  }
                }
            }
          }
          .loadingScreen(isLoading: postsData.posts.isEmpty, title: "Loading posts")
          .onAppear {
            // Do not load posts on a re-render
            guard postsData.posts.isEmpty else { return }
            postsData.loadPosts(sort: sorter.sort,
                                topInterval: sorter.topInterval)
          }
          .onDisappear {
            postsData.cancel()
          }
        }
        if postContainer is Subreddit && showSidebar {
          SidebarView(subreddit: postContainer as! Subreddit)
            .frame(minWidth: 200, maxWidth: 400)
        }
      }
    }
    .navigationTitle(postContainer.displayName)
  }
}

struct SidebarView: View {
  @EnvironmentObject var informationBarData: InformationBarData

  @State private var subscribed: Bool = false

  let subreddit: Subreddit

  init(subreddit: Subreddit) {
    self.subreddit = subreddit
    _subscribed = .init(initialValue: subreddit.userIsSubscriber)
  }

  var body: some View {
    VStack {
      HStack {
        if let headerImageUrl = subreddit.headerImg {
          WebImage(url: headerImageUrl)
        }
        Text(subreddit.displayName)
          .font(.largeTitle)
      }
      Divider()
      HStack {
        RoundedRectangle(cornerRadius: 2.0)
          .foregroundColor(subscribed ? .blue : Color(.darkGray))
          .overlay(
            Image(named: .rssFeed)
              .resizable()
              .frame(width: 24, height: 24),
            alignment: .center
          )
          .foregroundColor(.white)
          .onTapGesture {
            if subscribed {
              subreddit.unsubscribe { result in
                if case Result.success = result {
                  subscribed = false
                  informationBarData.loadSubscriptions()
                }
              }
            } else {
              subreddit.subscribe { result in
                if case Result.success = result {
                  subscribed = true
                  informationBarData.loadSubscriptions()
                }
              }
            }
          }
          .frame(width: 32, height: 32)
          .padding(.leading, 10)
        IllithidButton(label: {
          Image(systemName: "a.book.closed")
            .font(.title)
            .help("Show Wiki")
        }, mouseUp: {
          WindowManager.shared.showWindow(withId: "\(subreddit.name)/wiki",
                                          title: "\(subreddit.displayName) Wiki") {
            WikiPagesView(wikiData: .init(subreddit: subreddit))
          }
        })
        Spacer()
      }
      Divider()
      ScrollView {
        Text(subreddit.description ?? "")
      }
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
            Subreddit.fetch(name: subredditFullname) { result in
              switch result {
              case let .success(sub):
                subreddit = sub
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

// struct PostListView_Previews: PreviewProvider {
//  static var previews: some View {
//    PostListView(postsData: .init(), subreddit: .init(), reddit: .init())
//  }
// }
