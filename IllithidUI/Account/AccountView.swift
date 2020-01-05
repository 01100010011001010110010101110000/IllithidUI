//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
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
    .frame(minWidth: 250, maxWidth: 600, minHeight: 250, maxHeight: 800)
  }
}

struct AccountView: View {
  @ObservedObject var accountData: AccountData

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Overview", destination: AccountOverview(accountData: accountData))
        NavigationLink("Posts", destination: EmptyView())
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
