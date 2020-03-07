//
// InformationBarNavigationView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @EnvironmentObject var preferences: PreferencesData
  @EnvironmentObject var moderators: ModeratorData

  @ObservedObject var informationBarData = InformationBarData()
  let multiredditSearch = SearchData(for: [.subreddit])

  @State private var isEditingMulti: Bool = false
  @State private var editing: Multireddit.ID?
  @State private var providers: [String: PostListData] = [:]

  private func formData(id: String, for provider: PostProvider) -> PostListData {
    if let data = providers[id] { return data }
    else {
      let data = PostListData(provider: provider)
      DispatchQueue.main.async {
        self.providers[id] = data
      }
      return data
    }
  }

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Search", destination: SearchView(searchData: .init())
          .environmentObject(preferences)
          .environmentObject(moderators))
          .padding([.top])
        Section(header: Text("Front Page")) {
          NavigationLink("Home", destination: PostListView(data: formData(id: FrontPage.home.rawValue, for: FrontPage.home))
            .environmentObject(preferences)
            .environmentObject(moderators))
          NavigationLink("Popular", destination: PostListView(data: formData(id: FrontPage.popular.rawValue, for: FrontPage.popular))
            .environmentObject(preferences)
            .environmentObject(moderators))
          NavigationLink("All", destination: PostListView(data: formData(id: FrontPage.all.rawValue, for: FrontPage.all))
            .environmentObject(preferences)
            .environmentObject(moderators))
          NavigationLink("Random", destination: PostListView(data: formData(id: FrontPage.random.rawValue, for: FrontPage.random))
            .environmentObject(preferences)
            .environmentObject(moderators))
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
            NavigationLink(multireddit.name, destination: PostListView(data: self.formData(id: multireddit.id, for: multireddit))
              .environmentObject(self.preferences)
              .environmentObject(self.moderators))
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
            NavigationLink(destination: PostListView(data: self.formData(id: subreddit.id, for: subreddit))
              .environmentObject(self.preferences)
              .environmentObject(self.moderators)) {
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

struct MultiredditEditView: View {
  @EnvironmentObject var informationBarData: InformationBarData
  @ObservedObject var searchData: SearchData
  @State private var tapped: Bool = false

  let editingId: Multireddit.ID

  init(id: Multireddit.ID, searchData: SearchData) {
    editingId = id
    self.searchData = searchData
  }

  var body: some View {
    let editing = informationBarData.multiReddits.first { $0.id == editingId }!
    return VStack {
      VStack {
        Text(editing.displayName)
          .font(.title)
          .padding(.top)
        Text(editing.descriptionMd)
        Divider()
        VSplitView {
          List {
            ForEach(editing.subreddits) { subreddit in
              Text(subreddit.name)
            }
            .onDelete { indexSet in
              indexSet.forEach { index in
                editing.removeSubreddit(editing.subreddits[index]) { result in
                  switch result {
                  case .success:
                    self.informationBarData.loadMultireddits()
                  case let .failure(error):
                    print("Error removing \(editing.subreddits[index].name) from \(editing.displayName): \(error)")
                  }
                }
              }
            }
          }
          TextField("Search for subreddits to add", text: $searchData.query) {
            _ = self.searchData.search(for: self.searchData.query)
          }
          .padding([.top], 5)
          List {
            ForEach(searchData.subreddits.filter { subreddit in
              !editing.subreddits.map { $0.name }.contains(subreddit.displayName)
            }) { subreddit in
              HStack {
                Text(subreddit.displayName)
                Spacer()
                IllithidButton(action: {
                  editing.addSubreddit(subreddit) { result in
                    switch result {
                    case .success:
                      self.informationBarData.loadMultireddits()
                    case let .failure(error):
                      print("Error adding \(subreddit.displayName) to \(editing.displayName): \(error)")
                    }
                  }
                }, label: "Add to \(editing.displayName)")
              }
            }
          }
        }
      }
    }
    .frame(minWidth: 600, minHeight: 500)
  }
}
