//
// AccountView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

import Illithid

private struct AccountContentView: View {
  @ObservedObject var data: AccountData
  let from: KeyPath<AccountData, [Listing.Content]>

  var body: some View {
    List(data[keyPath: from]) { item in
      self.contentView(content: item)
    }
  }

  func contentView(content: Listing.Content) -> AnyView {
    switch content {
    case let .comment(comment):
      return CommentRowView(comment: comment)
        .eraseToAnyView()
    case let .post(post):
      return PostRowView(post: post)
        .eraseToAnyView()
    default:
      return EmptyView()
        .eraseToAnyView()
    }
  }
}

private struct AccountCommentsView: View {
  @ObservedObject var data: AccountData

  var body: some View {
    List(data.comments) { comment in
      CommentRowView(comment: comment)
    }
  }
}

private struct AccountPostsView: View {
  @ObservedObject var data: AccountData
  let from: KeyPath<AccountData, [Post]>

  var body: some View {
    List(data[keyPath: from]) { post in
      PostRowView(post: post)
    }
  }
}

struct AccountView: View {
  @ObservedObject var accountData: AccountData

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Overview", destination: AccountContentView(data: accountData, from: \.overview))
        NavigationLink("Posts", destination: AccountPostsView(data: accountData, from: \.submissions))
        NavigationLink("Comments", destination: AccountCommentsView(data: accountData))
        if accountData.account == Illithid.shared.accountManager.currentAccount {
          NavigationLink("Saved Items", destination: AccountContentView(data: accountData, from: \.saved))
          NavigationLink("Hidden", destination: AccountPostsView(data: accountData, from: \.hidden))
          NavigationLink("Upvoted", destination: AccountPostsView(data: accountData, from: \.upvoted))
          NavigationLink("Downvoted", destination: AccountPostsView(data: accountData, from: \.downvoted))
        }
      }
      .listStyle(SidebarListStyle())
    }
  }
}

// struct AccountView_Previews: PreviewProvider {
//  static var previews: some View {
//    AccountView()
//  }
// }
