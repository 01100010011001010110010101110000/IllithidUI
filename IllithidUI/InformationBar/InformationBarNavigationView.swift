//
// InformationBarNavigationView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @ObservedObject var preferences: PreferencesData = .shared

  @ObservedObject var informationBarData = InformationBarData()
  let multiredditSearch = SearchData(for: [.subreddit])

  @State private var isEditingMulti: Bool = false
  @State private var editing: Multireddit.ID?

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Search", destination: SearchView(searchData: .init()))
          .padding([.top])
        Section(header: Text("Front Page")) {
          NavigationLink("Home", destination: PostListView(data: informationBarData.postContainer(for: FrontPage.home)))
          NavigationLink("Popular", destination: PostListView(data: informationBarData.postContainer(for: FrontPage.popular)))
          NavigationLink("All", destination: PostListView(data: informationBarData.postContainer(for: FrontPage.all)))
          NavigationLink("Random", destination: PostListView(data: informationBarData.postContainer(for: FrontPage.random)))
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
            }
          }
        }
      }
      .listStyle(SidebarListStyle())
    }
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
