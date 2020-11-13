// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import SwiftUI

import Illithid
import Willow

struct SubredditsView: View {
  @ObservedObject var subredditData: SubredditListData

  var body: some View {
    NavigationView {
      List {
        ForEach(subredditData.subreddits) { subreddit in
          NavigationLink(destination: PostListView(postContainer: subreddit)) {
            SubredditRowView(subreddit: subreddit)
              .conditionalModifier(subreddit == subredditData.subreddits.last, OnAppearModifier {
                subredditData.loadSubreddits()
              })
          }
        }
      }
      .frame(minWidth: 300)

      NavigationPrompt(prompt: "Choose a subreddit")
    }
    .listStyle(SidebarListStyle())
    .onAppear {
      subredditData.loadSubreddits()
    }
  }
}

// #if DEBUG
// struct SubredditsView_Previews: PreviewProvider {
//  static var previews: some View {
//    SubredditsView(reddit: .init())
//      .previewDevice("MacBookPro15,1")
//      .environmentObject(SubredditData())
//  }
// }
// #endif
