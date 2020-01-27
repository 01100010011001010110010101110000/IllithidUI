//
// InformationBarNavigationView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @ObservedObject var informationBarData: InformationBarData = .init()

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Search", destination: SearchView(searchData: .init()))
          .padding([.top])
        Section(header: Text("Front Page")) {
          NavigationLink("Home", destination: PostListView(postContainer: FrontPage.best))
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
  }
}

struct InformationBarListView_Previews: PreviewProvider {
  static var previews: some View {
    InformationBarNavigationView(informationBarData: .init())
  }
}
