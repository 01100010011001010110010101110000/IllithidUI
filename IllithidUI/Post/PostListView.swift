//
// PostListView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import Combine
import Foundation
import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct PostListView: View {
  @EnvironmentObject var informationBarData: InformationBarData
  @ObservedObject var preferences: PreferencesData = .shared
  @ObservedObject private var sorter = SortModel(sort: PostSort.best, topInterval: .day)

  @State private var searchText: String = ""
  @State private var showSidebar: Bool = false
  @StateObject var postsData: PostListData

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
          .onReceive(self.sorter.$sort) { sort in
            guard !self.postsData.posts.isEmpty else { return }
            self.postsData.reload(sort: sort,
                                  topInterval: self.sorter.topInterval)
          }
          .onReceive(self.sorter.$topInterval) { interval in
            guard !self.postsData.posts.isEmpty else { return }
            self.postsData.reload(sort: self.sorter.sort,
                                  topInterval: interval)
          }
        HStack {
          TextField("Search Posts", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
          if postContainer is Subreddit {
            Button(action: {
              withAnimation {
                self.showSidebar.toggle()
              }
            }, label: {
              Image(named: .menuBars)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 15)
            })
          }
        }
        .padding([.bottom, .leading, .trailing], 10)
      }
      .background(Color(.controlBackgroundColor))

      HSplitView {
        List {
          ForEach(filteredPosts) { post in
            PostRowView(post: post)
              .onAppear {
                if post == self.filteredPosts.last {
                  self.postsData.loadPosts(sort: self.sorter.sort,
                                           topInterval: self.sorter.topInterval)
                }
              }
          }
        }
        .onAppear {
          self.postsData.loadPosts(sort: self.sorter.sort,
                                   topInterval: self.sorter.topInterval)
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
            if self.subscribed {
              self.subreddit.unsubscribe { result in
                if case Result.success = result {
                  self.subscribed = false
                  self.informationBarData.loadSubscriptions()
                }
              }
            } else {
              self.subreddit.subscribe { result in
                if case Result.success = result {
                  self.subscribed = true
                  self.informationBarData.loadSubscriptions()
                }
              }
            }
          }
          .frame(width: 32, height: 32)
          .padding(.leading, 10)
        IllithidButton(label: {
          Image(named: .book)
            .resizable()
            .frame(width: 24, height: 24)
            .tooltip("Show Wiki")
        }, mouseUp: {
          WindowManager.shared.showWindow(withId: "\(self.subreddit.name)/wiki",
                                          title: "\(self.subreddit.displayName) Wiki") {
            WikiPagesView(wikiData: .init(subreddit: self.subreddit))
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

// struct PostListView_Previews: PreviewProvider {
//  static var previews: some View {
//    PostListView(postsData: .init(), subreddit: .init(), reddit: .init())
//  }
// }
