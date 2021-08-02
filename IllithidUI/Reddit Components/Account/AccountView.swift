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

import SwiftUI

import Alamofire
import Illithid

// MARK: - AccountView

struct AccountView: View {
  // MARK: Lifecycle

  init(account: Account) {
    _accountData = .init(wrappedValue: .init(account: account))
  }

  init(name: String) {
    _accountData = .init(wrappedValue: .init(name: name))
  }

  // MARK: Internal

  var body: some View {
    if accountData.account != nil {
      TabView(selection: $selected) {
        Content(data: accountData, content: .overview)
          .tabItem {
            Label("Overview", systemImage: "newspaper")
          }
          .tag(AccountContent.overview)
        Content(data: accountData, content: .submissions)
          .tabItem {
            Label("Posts", systemImage: "paperplane")
          }
          .tag(AccountContent.submissions)
        Content(data: accountData, content: .comments)
          .tabItem {
            Label("Comments", systemImage: "text.bubble")
          }
          .tag(AccountContent.comments)
        if accountData.account == Illithid.shared.accountManager.currentAccount {
          Content(data: accountData, content: .saved)
            .tabItem {
              Label("Saved", systemImage: "bookmark")
            }
            .tag(AccountContent.saved)
          Content(data: accountData, content: .hidden)
            .tabItem {
              Label("Hidden", systemImage: "eye.slash")
            }
            .tag(AccountContent.hidden)
          Content(data: accountData, content: .upvoted)
            .tabItem {
              Label("Upvoted", systemImage: "arrow.up")
            }
            .tag(AccountContent.upvoted)
          Content(data: accountData, content: .downvoted)
            .tabItem {
              Label("Downvoted", systemImage: "arrow.down")
            }
            .tag(AccountContent.downvoted)
        }
      }
      .padding(.top)
    } else {
      Rectangle()
        .foregroundColor(.clear)
        .loadingScreen(isLoading: accountData.account == nil, title: "Loading account")
    }
  }

  // MARK: Private

  @State private var selected: AccountContent = .overview

  @StateObject private var accountData: AccountData
}

// MARK: - Content

private struct Content: View {
  @ObservedObject var data: AccountData
  @ObservedObject var preferences: PreferencesData = .shared
  @StateObject private var sorter: SortModel<AccountContentSort> = .init(sort: .new, topInterval: .day)

  let content: AccountContent

  var body: some View {
    VStack {
      HStack {
        SortController(model: sorter)

        RefreshButton {
          data.reload(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
        }
        .keyboardShortcut("r")

        Spacer()
      }
      .padding([.leading, .top, .bottom], 10)

      List {
        ForEach(data.content[content]!) { item in
          switch item {
          case let .comment(comment):
            CommentRowView(isCollapsed: .constant(false), comment: comment)
              .onAppear {
                if item == data.content[content]!.last {
                  data.loadContent(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
                }
              }
          case let .post(post):
            if shouldShowPost(post) {
              PostRowView(post: post, selection: .constant(nil))
                .onAppear {
                  if item == data.content[content]!.last {
                    data.loadContent(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
                  }
                }
            }
          default:
            EmptyView()
          }
        }
      }
      .loadingScreen(isLoading: data.isLoading[content, default: false] && data.content[content]!.isEmpty)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      data.loadContent(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
    }
    .onReceive(sorter.$sort.dropFirst()) { sort in
      data.reload(content: content, sort: sort, topInterval: sorter.topInterval)
    }
    .onReceive(sorter.$topInterval.dropFirst()) { interval in
      data.reload(content: content, sort: sorter.sort, topInterval: interval)
    }
  }

  func shouldShowPost(_ post: Post) -> Bool {
    if preferences.hideNsfw, post.over18 {
      return false
    }
    return true
  }
}
