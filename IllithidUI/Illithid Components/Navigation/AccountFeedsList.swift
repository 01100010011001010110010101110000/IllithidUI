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

struct AccountFeedsList: View {
  // MARK: Lifecycle

  init(selection: Binding<String?>) {
    _projectedSelection = selection
  }

  // MARK: Internal

  @Binding var projectedSelection: String?
  @EnvironmentObject var informationBarData: InformationBarData

  var body: some View {
    List(selection: $selection) {
      Section(header: Text("Illithid")) {
        ForEach(IllithidPages.allCases) { page in
          Label(page.title, systemImage: page.systemImageIconName)
            .help(page.title)
        }
      }
      Divider()
      Section(header: Text("Front Page")) {
        ForEach(FrontPage.allCases) { page in
          Label(page.title, systemImage: page.systemImageIconName)
            .help(page.displayName)
        }
      }
      Divider()
      Section(header: Text("Multireddits")) {
        ForEach(filteredPostProviders(informationBarData.multireddits)) { multireddit in
          HStack {
            SubredditIcon(multireddit: multireddit)
              .frame(width: 24, height: 24)
            Text(multireddit.displayName)
          }
          .help(multireddit.displayName)
        }
      }
      Divider()
      Section(header: Text("Subscribed")) {
        ForEach(filteredPostProviders(informationBarData.subscribedSubreddits)) { subreddit in
          HStack {
            SubredditIcon(subreddit: subreddit)
              .frame(width: 24, height: 24)
            Text(subreddit.displayName)
          }
          .help(subreddit.displayName)
        }
      }
    }
    .onChange(of: selection) { selection in
      projectedSelection = selection
    }
  }

  // MARK: Private

  @State private var selection: String?
  @ObservedObject private var preferences: PreferencesData = .shared

  private func filteredPostProviders<Provider: PostProvider>(_ providers: [Provider]) -> [Provider] {
    if preferences.hideNsfw {
      return providers.filter { !$0.isNsfw }
    } else {
      return providers
    }
  }
}
