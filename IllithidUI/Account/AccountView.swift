//
// {file}
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import SwiftUI

import Illithid

struct AccountView: View {
  let account: Account

  var body: some View {
    NavigationView {
      List {
        NavigationLink("Overview", destination: EmptyView())
        NavigationLink("Posts", destination: EmptyView())
        NavigationLink("Comments", destination: EmptyView())
        NavigationLink("Saved Items", destination: EmptyView())
        NavigationLink("Hidden", destination: EmptyView())
        NavigationLink("Upvoted", destination: EmptyView())
        NavigationLink("Downvoted", destination: EmptyView())
      }
    .listStyle(SidebarListStyle())
    }
  }
}

// struct AccountView_Previews: PreviewProvider {
//  static var previews: some View {
//    AccountView()
//  }
// }
