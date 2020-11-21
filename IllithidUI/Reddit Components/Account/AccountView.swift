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

  @EnvironmentObject var informationBarData: InformationBarData

  var body: some View {
    TabView {
      Content(data: accountData, content: .overview)
        .tabItem {
          Label("Overview", systemImage: "newspaper")
        }
      Content(data: accountData, content: .submissions)
        .tabItem {
          Label("Posts", systemImage: "paperplane")
        }
      Content(data: accountData, content: .comments)
        .tabItem {
          Label("Comments", systemImage: "text.bubble")
        }
      if accountData.account == Illithid.shared.accountManager.currentAccount {
        Content(data: accountData, content: .saved)
          .tabItem {
            Label("Saved", systemImage: "bookmark")
          }
        Content(data: accountData, content: .hidden)
          .tabItem {
            Label("Hidden", systemImage: "eye.slash")
          }
        Content(data: accountData, content: .upvoted)
          .tabItem {
            Label("Upvoted", systemImage: "arrow.up")
          }
        Content(data: accountData, content: .downvoted)
          .tabItem {
            Label("Downvoted", systemImage: "arrow.down")
          }
      }
    }
    .environmentObject(informationBarData)
    .padding(.top)
  }

  // MARK: Private

  @StateObject private var accountData: AccountData
}

// MARK: - Content

private struct Content: View {
  @ObservedObject var data: AccountData
  @StateObject private var sorter: SortModel<AccountContentSort> = .init(sort: .new, topInterval: .day)

  let content: AccountContent

  var body: some View {
    VStack {
      SortController(model: sorter)
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
            PostRowView(post: post)
              .onAppear {
                if item == data.content[content]!.last {
                  data.loadContent(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
                }
              }
          default:
            EmptyView()
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      data.loadContent(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
    }
    .onReceive(sorter.$sort) { sort in
      guard !data.content[content]!.isEmpty else { return }
      data.clearContent(content: content)
      data.loadContent(content: content, sort: sort, topInterval: sorter.topInterval)
    }
    .onReceive(sorter.$topInterval) { interval in
      guard !data.content[content]!.isEmpty else { return }
      data.clearContent(content: content)
      data.loadContent(content: content, sort: sorter.sort, topInterval: interval)
    }
  }
}

// struct AccountView_Previews: PreviewProvider {
//  static var previews: some View {
//    AccountView()
//  }
// }
