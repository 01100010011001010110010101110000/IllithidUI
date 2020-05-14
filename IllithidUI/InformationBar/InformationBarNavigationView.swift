//
// InformationBarNavigationView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 5/12/20
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @ObservedObject var preferences: PreferencesData = .shared

  @ObservedObject var informationBarData = InformationBarData()
  let multiredditSearch = SearchData(for: [.subreddit])

  @State private var isEditingMulti: Bool = false
  @State private var editing: Multireddit.ID?

  private var accountView: some View {
    AccountView(accountData: .init(account: Illithid.shared.accountManager.currentAccount))
      .environmentObject(self.informationBarData)
  }

  var body: some View {
    NavigationView {
      List {
        Section(header: Text("Meta")) {
          NavigationLink("Account", destination: accountView)
            .openableInNewTab(id: Illithid.shared.accountManager.currentAccount?.id ?? "account",
                              title: Illithid.shared.accountManager.currentAccount?.name ?? "Account") {
              self.accountView
            }
          NavigationLink("Search", destination: SearchView(searchData: .init()))
            .openableInNewTab(id: "search", title: "Search") { SearchView(searchData: .init()) }
        }
        Section(header: Text("Front Page")) {
          ForEach(FrontPage.allCases) { page in
            NavigationLink(page.title, destination: PostListView(data: self.informationBarData.postContainer(for: page)))
              .openableInNewTab(id: page.id, title: page.title) { PostListView(postContainer: page) }
          }
        }

        Section(header: Text("Favorites")) {
          EmptyView()
        }

        Section(header: Text("Multireddits")) {
          ForEach(informationBarData.multiReddits.filter { multi in
            if preferences.hideNsfw {
              return !(multi.over18 ?? false)
            } else {
              return true
            }
          }) { multireddit in
            NavigationLink(multireddit.name, destination: PostListView(data: self.informationBarData.postContainer(for: multireddit)))
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
            NavigationLink(destination: PostListView(data: self.informationBarData.postContainer(for: subreddit))) {
              HStack {
                Text(subreddit.displayName)
                Spacer()
              }
              .openableInNewTab(id: subreddit.id, title: subreddit.displayName) { PostListView(postContainer: subreddit) }
            }
          }
        }
      }
      .listStyle(SidebarListStyle())
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

struct InformationBarListView_Previews: PreviewProvider {
  static var previews: some View {
    InformationBarNavigationView(informationBarData: .init())
  }
}
