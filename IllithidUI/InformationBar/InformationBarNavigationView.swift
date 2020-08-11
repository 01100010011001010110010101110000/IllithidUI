//
// InformationBarNavigationView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/9/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct InformationBarNavigationView: View {
  @ObservedObject var preferences: PreferencesData = .shared

  @StateObject private var multiredditSearch = SearchData(for: [.subreddit])
  @StateObject private var informationBarData = InformationBarData()
  @State private var isEditingMulti: Bool = false
  @State private var editing: Multireddit.ID?
  @State private var selection: String? = nil

  @ViewBuilder private var accountView: some View {
    if let account = Illithid.shared.accountManager.currentAccount {
      AccountView(account: account)
        .environmentObject(informationBarData)
    } else {
      Text("There is no logged in account")
    }
  }

  var body: some View {
    NavigationView {
      List(selection: $selection) {
        Section(header: Text("Meta")) {
          NavigationLink(destination: accountView, label: { Label("Account", systemImage: "person.crop.circle") })
            .tag("__account__")
            .openableInNewTab(id: Illithid.shared.accountManager.currentAccount?.id ?? "account",
                              title: Illithid.shared.accountManager.currentAccount?.name ?? "Account") {
              accountView
            }
          NavigationLink(destination: SearchView(), label: { Label("Search", systemImage: "magnifyingglass") })
            .tag("__search__")
            .openableInNewTab(id: "search", title: "Search") { SearchView() }
        }
        Section(header: Text("Front Page")) {
          ForEach(FrontPage.allCases) { page in
            NavigationLink(destination: PostListView(postContainer: page), label: { Label(page.title, systemImage: page.systemImageIconName) })
              .tag(page)
              .openableInNewTab(id: page.id, title: page.title) { PostListView(postContainer: page) }
          }
        }

        Section(header: Text("Multireddits")) {
          ForEach(informationBarData.multiReddits.filter { multi in
            if preferences.hideNsfw {
              return !(multi.over18 ?? false)
            } else {
              return true
            }
          }) { multireddit in
            NavigationLink(destination: PostListView(postContainer: multireddit)) {
              HStack {
                SubredditIcon(multireddit: multireddit)
                  .frame(width: 24, height: 24)
                Text(multireddit.displayName)
              }
            }
            .tag("m/\(multireddit.id)")
            .openableInNewTab(id: multireddit.id, title: multireddit.name) { PostListView(postContainer: multireddit) }
            .contextMenu {
              Button(action: {
                isEditingMulti = true
                editing = multireddit.id
              }) {
                Text("Edit Multireddit")
              }
            }
          }
        }

        Section(header: Text("Subscribed")) {
          ForEach(informationBarData.subscribedSubreddits.filter { sub in
            if preferences.hideNsfw {
              return !(sub.over18 ?? false)
            } else {
              return true
            }
          }) { subreddit in
            NavigationLink(destination: PostListView(postContainer: subreddit)) {
              HStack {
                SubredditIcon(subreddit: subreddit)
                  .frame(width: 24, height: 24)
                Text(subreddit.displayName)
              }
              .openableInNewTab(id: subreddit.id, title: subreddit.displayName) { PostListView(postContainer: subreddit) }
            }
            .tag(subreddit.name)
          }
        }
      }
      .listStyle(SidebarListStyle())

      NavigationPrompt(prompt: "Open the front page")
    }
    .environmentObject(informationBarData)
    .sheet(isPresented: $isEditingMulti, onDismiss: {
      multiredditSearch.clearData()
      multiredditSearch.clearQueryText()
    }, content: {
      VStack {
        MultiredditEditView(id: editing!, searchData: multiredditSearch)
          .environmentObject(informationBarData)
        HStack {
          Spacer()
          Button(action: {
            isEditingMulti = false
          }) {
            Text("Done")
          }
          .padding([.trailing, .bottom])
        }
      }
    })
  }
}

extension FrontPage {
  var systemImageIconName: String {
    switch self {
    case .all:
      return "asterisk.circle"
    case .home:
      return "house"
    case .popular:
      return "arrow.up.right.square"
    case .random:
      return "shuffle"
    }
  }
}

struct InformationBarListView_Previews: PreviewProvider {
  static var previews: some View {
    InformationBarNavigationView()
  }
}
