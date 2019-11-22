//
//  RootView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 8/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

enum TabSelection {
  case information
  case search
}

struct RootView: View {
  @State private var selection: TabSelection = .information
  let reddit: Illithid = .shared

  var body: some View {
    // TODO: Don't display the tab bar
    TabView(selection: $selection) {
      InformationBarNavigationView(informationBarData: .init())
        .tabItem { Text("Information") }
        .tag(TabSelection.information)
      SearchView(searchData: .init())
        .tabItem { Text("Search") }
        .tag(TabSelection.search)
    }
  }
}

// #if DEBUG
// struct RootView_Previews: PreviewProvider {
//    static var previews: some View {
//        RootView()
//    }
// }
// #endif
