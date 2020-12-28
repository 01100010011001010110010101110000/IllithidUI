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
import SDWebImageSwiftUI

// MARK: - InformationBarNavigationView

struct InformationBarNavigationView: View {
  // MARK: Internal

  @ObservedObject var preferences: PreferencesData = .shared

  var body: some View {
    NavigationView {
      List(selection: $selection) {
        Section(header: Text("Meta")) {
          NavigationLink(destination: accountView, label: { Label("Account", systemImage: "person.crop.circle") })
            .help("Account view")
            .tag("__account__")
            .openableInNewTab(id: Illithid.shared.accountManager.currentAccount?.id ?? "account",
                              title: Illithid.shared.accountManager.currentAccount?.name ?? "Account") {
              accountView
            }
          NavigationLink(destination: SearchView(), label: { Label("Search", systemImage: "magnifyingglass") })
            .help("Search Reddit")
            .tag("__search__")
            .openableInNewTab(id: "search", title: "Search") { SearchView() }
        }
        Section(header: Text("Front Page")) {
          ForEach(FrontPage.allCases) { page in
            NavigationLink(destination: PostListView(postContainer: page), label: { Label(page.title, systemImage: page.systemImageIconName) })
              .help(page.displayName)
              .tag(page)
              .openableInNewTab(id: page.id, title: page.title) { PostListView(postContainer: page) }
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
            .tag("m/\(multireddit.id)")
            .openableInNewTab(id: multireddit.id, title: multireddit.name) { PostListView(postContainer: multireddit) }
            .contextMenu {
              Button(action: {
                editing = multireddit
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
            NavigationLink(destination: PostListView(postContainer: subreddit)) {
              HStack {
                SubredditIcon(subreddit: subreddit)
                  .frame(width: 24, height: 24)
                Text(subreddit.displayName)
              }
              .openableInNewTab(id: subreddit.id, title: subreddit.displayName) { PostListView(postContainer: subreddit) }
            }
            .help(subreddit.displayName)
            .tag(subreddit.name)
          }
        }
      }
      .listStyle(SidebarListStyle())
      .onAppear {
        informationBarData.loadAccountData()
      }

      NavigationPrompt(prompt: "Open the front page")
    }
    .environmentObject(informationBarData)
    .sheet(item: $editing, onDismiss: {
      multiredditSearch.reset()
    }, content: { multireddit in
      VStack {
        MultiredditEditView(editing: multireddit, searchData: multiredditSearch)
          .environmentObject(informationBarData)
        HStack {
          Spacer()
          Button(action: {
            editing = nil
          }) {
            Text("Done")
          }
          .padding([.trailing, .bottom])
        }
      }
    })
  }

  // MARK: Private

  @StateObject private var multiredditSearch = SearchData(for: [.subreddit])
  @StateObject private var informationBarData = InformationBarData()
  @State private var editing: Multireddit?
  @State private var selection: String? = nil

  @ViewBuilder private var accountView: some View {
    if let account = Illithid.shared.accountManager.currentAccount {
      AccountView(account: account)
    } else {
      Text("There is no logged in account")
    }
  }
}

extension FrontPage {
  var systemImageIconName: String {
    switch self {
    case .all:
      return "asterisk.circle"
    case .home:
      return "house"
    case .popular:
      return "arrow.up.right.square"
    case .random:
      return "shuffle"
    }
  }
}

// MARK: - InformationBarListView_Previews

struct InformationBarListView_Previews: PreviewProvider {
  static var previews: some View {
    InformationBarNavigationView()
  }
}
