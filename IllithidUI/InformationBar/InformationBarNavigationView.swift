//
//  InformationBarListView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/20/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct InformationBarNavigationView: View {
  @ObservedObject var informationBarData: InformationBarData = .init()

  var body: some View {
    NavigationView {
      List {
        Section(header: Text("Front Page")) {
          NavigationLink(destination: FrontPageListView(page: .best)) {
            Text("Home")
          }
          NavigationLink(destination: FrontPageListView(page: .popular)) {
            Text("Popular")
          }
          NavigationLink(destination: FrontPageListView(page: .all)) {
            Text("All")
          }
          NavigationLink(destination: FrontPageListView(page: .random)) {
            Text("Random")
          }
        }

        Section(header: Text("Favorites")) {
          EmptyView()
        }

        Section(header: Text("Multireddits")) {
          ForEach(informationBarData.multiReddits) { multireddit in
            NavigationLink(destination: MultiredditListView(multireddit: multireddit)) {
              Text(multireddit.name)
            }
          }
        }

        Section(header: Text("Subscribed")) {
          ForEach(informationBarData.subscribedSubreddits) { subreddit in
            NavigationLink(destination: PostListView(postsData: .init(), subreddit: subreddit)) {
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
