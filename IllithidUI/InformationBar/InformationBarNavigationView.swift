//
// InformationBarNavigationView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @ObservedObject var informationBarData: InformationBarData = .init()
  let multiredditSearch = SearchData(for: [.subreddit])

  @State private var isEditingMulti: Bool = false
  @State private var editing: Multireddit.ID?

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Search", destination: SearchView(searchData: .init()))
          .padding([.top])
        Section(header: Text("Front Page")) {
          NavigationLink("Home", destination: PostListView(postContainer: FrontPage.home))
          NavigationLink("Popular", destination: PostListView(postContainer: FrontPage.popular))
          NavigationLink("All", destination: PostListView(postContainer: FrontPage.all))
          NavigationLink("Random", destination: PostListView(postContainer: FrontPage.random))
        }

        Section(header: Text("Favorites")) {
          EmptyView()
        }

        Section(header: Text("Multireddits")) {
          ForEach(informationBarData.multiReddits) { multireddit in
            NavigationLink(multireddit.name, destination: PostListView(postContainer: multireddit))
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
          ForEach(informationBarData.subscribedSubreddits) { subreddit in
            NavigationLink(destination: PostListView(postContainer: subreddit)) {
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
      self.multiredditSearch.clearQuery()
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
            self.searchData.search(for: self.searchData.query)
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
