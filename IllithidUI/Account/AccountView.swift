//
// AccountView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/1/20
//

import SwiftUI

import Alamofire
import Illithid

struct AccountView: View {
  @EnvironmentObject var informationBarData: InformationBarData

  @StateObject var accountData: AccountData

  init(account: Account) {
    _accountData = .init(wrappedValue: .init(account: account))
  }

  init(name: String) {
    _accountData = .init(wrappedValue: .init(name: name))
  }

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Overview", destination: Content(data: accountData, content: .overview))
        NavigationLink("Posts", destination: Content(data: accountData, content: .submissions))
        NavigationLink("Comments", destination: Content(data: accountData, content: .comments))
        if accountData.account == Illithid.shared.accountManager.currentAccount {
          NavigationLink("Saved Items", destination: Content(data: accountData, content: .saved))
          NavigationLink("Hidden", destination: Content(data: accountData, content: .hidden))
          NavigationLink("Upvoted", destination: Content(data: accountData, content: .upvoted))
          NavigationLink("Downvoted", destination: Content(data: accountData, content: .downvoted))
        }
      }
      .listStyle(SidebarListStyle())
    }
    .environmentObject(informationBarData)
  }
}

private struct Content: View {
  @ObservedObject var data: AccountData
  @StateObject var sorter: SortModel<AccountContentSort> = .init(sort: .new, topInterval: .day)

  let content: AccountContent

  var body: some View {
    List {
      SortController(model: sorter)
      ForEach(data.content[content]!) { item in
        contentView(content: item)
          .onAppear {
            if item == data.content[content]!.last {
              data.loadContent(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
            }
          }
      }
    }
    .onAppear {
      data.loadContent(content: content, sort: sorter.sort, topInterval: sorter.topInterval)
    }
    .onReceive(sorter.$sort) { sort in
      data.clearContent(content: content)
      data.loadContent(content: content, sort: sort, topInterval: sorter.topInterval)
    }
    .onReceive(sorter.$topInterval) { interval in
      data.clearContent(content: content)
      data.loadContent(content: content, sort: sorter.sort, topInterval: interval)
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

// struct AccountView_Previews: PreviewProvider {
//  static var previews: some View {
//    AccountView()
//  }
// }
