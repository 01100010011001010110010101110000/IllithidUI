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
          List(selection: $selection) {
            ForEach(filteredPosts) { post in
              PostRowView(post: post)
                .tag(post.id)
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
            .frame(minWidth: 300)
        }
      }
    }
    .navigationTitle(postContainer.displayName)
  }

  // MARK: Private

  @State private var selection: Subreddit? = nil
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

// MARK: - SidebarView

struct SidebarView: View {
  // MARK: Lifecycle

  init(subreddit: Subreddit) {
    self.subreddit = subreddit
    _subscribed = .init(initialValue: subreddit.userIsSubscriber ?? false)
  }

  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData

  let subreddit: Subreddit

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
        if let description = subreddit.description {
          Markdown(mdString: description)
            .padding()
        } else {
          Text("No sidebar text found")
            .padding()
        }
      }
    }
    .background(Color(.controlBackgroundColor))
  }

  // MARK: Private

  @State private var subscribed: Bool = false
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
