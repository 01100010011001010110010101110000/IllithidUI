// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import Combine
import Foundation
import SwiftUI

import Illithid
import SDWebImageSwiftUI

// MARK: - PostListView

struct PostListView: View {
  // MARK: Lifecycle

  init(postContainer: PostProvider) {
    self.postContainer = postContainer
    _postsData = .init(wrappedValue: .init(provider: postContainer))
  }

  // MARK: Internal

  @Environment(\.navigationLayout) var layout
  @EnvironmentObject var informationBarData: InformationBarData
  @ObservedObject var preferences: PreferencesData = .shared

  let postContainer: PostProvider

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
              .help("Toggle sidebar")
          }
        }
        .padding([.bottom, .leading, .trailing], 10)
      }
      .background(Color(.controlBackgroundColor))

      HSplitView {
        switch layout {
        case .classic, .compact:
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
          List(filteredPosts, selection: $selection) { post in
            PostRowView(post: post)
              .onAppear {
                if post == filteredPosts.last {
                  postsData.loadPosts(sort: sorter.sort,
                                      topInterval: sorter.topInterval)
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

        // TODO: This conditional is, as of macOS 11 beta 10, causing a crash when switching between navigation view links
        // For now, it will be commented out and we will always show the sidebar
        if // showSidebar,
          postContainer is Subreddit {
          SubredditSidebar(subreddit: postContainer as! Subreddit)
            .frame(minWidth: 300, maxWidth: 600)
        }
      }
    }
    .navigationTitle(postContainer.displayName)
  }

  // MARK: Private

  @State private var selection: Post? = nil
  @State private var searchText: String = ""
  @State private var showSidebar: Bool = false
  @StateObject private var sorter = SortModel(sort: PostSort.best, topInterval: .day)
  @StateObject private var postsData: PostListData

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
}

// MARK: - SubredditLoader

/// Loads a PostListView when we have only a subreddit name
struct SubredditLoader: View, Identifiable {
  // MARK: Lifecycle

  init(fullname subredditFullname: Fullname) {
    self.subredditFullname = subredditFullname
  }

  // MARK: Internal

  let subredditFullname: Fullname

  var id: String { subredditFullname }

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

  // MARK: Private

  @State private var subreddit: Subreddit?
}

// struct PostListView_Previews: PreviewProvider {
//  static var previews: some View {
//    PostListView(postsData: .init(), subreddit: .init(), reddit: .init())
//  }
// }
