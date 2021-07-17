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

import Foundation
import SwiftUI

import Illithid

struct TriplePaneLayoutView: View {
  @EnvironmentObject var informationBarData: InformationBarData
  @ObservedObject var preferences: PreferencesData = .shared

  var body: some View {
    NavigationView {
      List {
        Section(header: Text("Illithid")) {
          ForEach(IllithidPages.allCases) { page in
            NavigationLink(destination: page.destinationView) {
              Label(page.title, systemImage: page.systemImageIconName)
            }
            .help(page.title)
          }
        }

        Section(header: Text("Front Page")) {
          ForEach(FrontPage.allCases) { page in
            NavigationLink(destination: PostListView(postContainer: page)) {
              Label(page.title, systemImage: page.systemImageIconName)
            }
            .help(page.displayName)
          }
        }

        Section(header: Text("Multireddits")) {
          ForEach(informationBarData.multireddits.filter { multi in
            if preferences.hideNsfw {
              return !(multi.over18 ?? false)
            } else {
              return true
            }
          }) { multireddit in
            NavigationLink(destination: PostListView(postContainer: multireddit)) {
              HStack {
                SubredditIcon(multireddit: multireddit)
                  .frame(width: 24, height: 24)
                Text(multireddit.displayName)
              }
            }
            .help(multireddit.displayName)
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
            NavigationLink(destination: PostListView(postContainer: subreddit)) {
              HStack {
                SubredditIcon(subreddit: subreddit)
                  .frame(width: 24, height: 24)
                Text(subreddit.displayName)
              }
            }
            .help(subreddit.displayName)
          }
        }
      }

      NavigationPrompt(prompt: "Welcome to the only newspaper that flays your mind")
    }
  }
}
