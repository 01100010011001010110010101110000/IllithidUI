//
// AccountView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 4/2/20
//

import SwiftUI

import Alamofire
import Illithid

private struct Content: View {
  @ObservedObject var data: AccountData
  @ObservedObject var sorter: SortModel<AccountContentSort> = .init(sort: .new, topInterval: .day)

  let content: AccountContent

  var body: some View {
    List {
      SortController(model: sorter)
      ForEach(data.content[content]!) { item in
        self.contentView(content: item)
          .onAppear {
            if item == self.data.content[self.content]!.last {
              self.data.loadContent(content: self.content, sort: self.sorter.sort, topInterval: self.sorter.topInterval)
            }
          }
      }
    }
    .onAppear {
      self.data.loadContent(content: self.content, sort: self.sorter.sort, topInterval: self.sorter.topInterval)
    }
    .onReceive(sorter.$sort) { _ in
      self.data.clearContent(content: self.content)
      self.data.loadContent(content: self.content, sort: self.sorter.sort, topInterval: self.sorter.topInterval)
    }
    .onReceive(sorter.$topInterval) { _ in
      self.data.clearContent(content: self.content)
      self.data.loadContent(content: self.content, sort: self.sorter.sort, topInterval: self.sorter.topInterval)
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

struct AccountView: View {
  @ObservedObject var accountData: AccountData

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Overview", destination: Content(data: self.accountData, content: .overview))
        NavigationLink("Posts", destination: Content(data: self.accountData, content: .submissions))
        NavigationLink("Comments", destination: Content(data: self.accountData, content: .comments))
        if accountData.account == Illithid.shared.accountManager.currentAccount {
          NavigationLink("Saved Items", destination: Content(data: self.accountData, content: .saved))
          NavigationLink("Hidden", destination: Content(data: self.accountData, content: .hidden))
          NavigationLink("Upvoted", destination: Content(data: self.accountData, content: .upvoted))
          NavigationLink("Downvoted", destination: Content(data: self.accountData, content: .downvoted))
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
