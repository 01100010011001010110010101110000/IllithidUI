//
// AccountView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

import Illithid

struct AccountOverview: View {
  @ObservedObject var accountData: AccountData

  var body: some View {
    Text(accountData.account?.name ?? "No Account")
  }
}

struct AccountCommentsView: View {
  @ObservedObject var accountData: AccountData

  var body: some View {
    List {
      ForEach(accountData.comments) { comment in
        CommentRowView(comment: comment)
      }
    }
  }
}

struct AccountPostsView: View {
  @ObservedObject var accountData: AccountData

  var body: some View {
    List {
      ForEach(accountData.submissions) { post in
        PostRowView(post: post)
      }
    }
  }
}

struct AccountView: View {
  @ObservedObject var accountData: AccountData

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Overview", destination: AccountOverview(accountData: accountData))
        NavigationLink("Posts", destination: AccountPostsView(accountData: accountData))
        NavigationLink("Comments", destination: AccountCommentsView(accountData: accountData))
        NavigationLink("Saved Items", destination: EmptyView())
        NavigationLink("Hidden", destination: EmptyView())
        NavigationLink("Upvoted", destination: EmptyView())
        NavigationLink("Downvoted", destination: EmptyView())
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
