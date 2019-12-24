//
// InformationBarNavigationView.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @ObservedObject var informationBarData: InformationBarData = .init()

  var body: some View {
    NavigationView {
      List {
        Section(header: Text("Front Page")) {
          NavigationLink(destination: PostListView(postContainer: FrontPage.best)) {
            Text("Home")
          }
          NavigationLink(destination: PostListView(postContainer: FrontPage.popular)) {
            Text("Popular")
          }
          NavigationLink(destination: PostListView(postContainer: FrontPage.all)) {
            Text("All")
          }
          NavigationLink(destination: PostListView(postContainer: FrontPage.random)) {
            Text("Random")
          }
        }

        Section(header: Text("Favorites")) {
          EmptyView()
        }

        Section(header: Text("Multireddits")) {
          ForEach(informationBarData.multiReddits) { multireddit in
            NavigationLink(destination: PostListView(postContainer: multireddit)) {
              Text(multireddit.name)
            }
          }
        }

        Section(header: Text("Subscribed")) {
          ForEach(informationBarData.subscribedSubreddits) { subreddit in
            NavigationLink(destination: PostListView(postContainer: subreddit)) {
              Text(subreddit.displayName)
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
