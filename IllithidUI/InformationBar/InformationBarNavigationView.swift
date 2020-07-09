//
// InformationBarNavigationView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/6/20
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @ObservedObject var preferences: PreferencesData = .shared

  @ObservedObject var informationBarData = InformationBarData()
  let multiredditSearch = SearchData(for: [.subreddit])

  @State private var isEditingMulti: Bool = false
  @State private var editing: Multireddit.ID?

  @State private var selection: String? = nil

  private var accountView: AnyView {
    if let account = Illithid.shared.accountManager.currentAccount {
      return AccountView(account: account)
        .environmentObject(informationBarData)
        .eraseToAnyView()
    } else {
      return EmptyView()
        .eraseToAnyView()
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
              self.accountView
            }
          NavigationLink(destination: VStack { Spacer(); Text("asgbvhjdas"); Spacer() }, label: { Label("Search", systemImage: "magnifyingglass") })
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
            NavigationLink(multireddit.name, destination: PostListView(postContainer: multireddit))
              .tag("m/\(multireddit.id)")
              .openableInNewTab(id: multireddit.id, title: multireddit.name) { PostListView(postContainer: multireddit) }
              .contextMenu {
                Button(action: {
                  self.isEditingMulti = true
                  self.editing = multireddit.id
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
                Text(subreddit.displayName)
                Spacer()
              }
              .openableInNewTab(id: subreddit.id, title: subreddit.displayName) { PostListView(postContainer: subreddit) }
            }
            .tag(subreddit.name)
          }
        }
      }
      .listStyle(SidebarListStyle())

      Text("Open the front page")
        .font(.largeTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .environmentObject(informationBarData)
    .sheet(isPresented: self.$isEditingMulti, onDismiss: {
      self.multiredditSearch.clearData()
      self.multiredditSearch.clearQueryText()
    }, content: {
      VStack {
        MultiredditEditView(id: self.editing!, searchData: self.multiredditSearch)
          .environmentObject(self.informationBarData)
        HStack {
          Spacer()
          Button(action: {
            self.isEditingMulti = false
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
    InformationBarNavigationView(informationBarData: .init())
  }
}
