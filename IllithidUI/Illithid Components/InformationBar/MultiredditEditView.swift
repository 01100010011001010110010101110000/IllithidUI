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

struct MultiredditEditView: View {
  // MARK: Lifecycle

  init(editing multireddit: Multireddit) {
    editing = multireddit
  }

  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData
  @StateObject var searchData: SearchData = .init(for: [.subreddit])
  let editing: Multireddit

  var body: some View {
    VStack {
      VStack {
        Text(editing.displayName)
          .font(.title)
          .padding(.top)
        Text(editing.descriptionMd)
        Divider()
        HSplitView {
          List {
            ForEach(editing.subreddits) { subreddit in
              Text(subreddit.name)
            }
            .onDelete { indexSet in
              indexSet.forEach { index in
                editing.removeSubreddit(editing.subreddits[index]) { result in
                  switch result {
                  case .success:
                    informationBarData.loadMultireddits()
                  case let .failure(error):
                    print("Error removing \(editing.subreddits[index].name) from \(editing.displayName): \(error)")
                  }
                }
              }
            }
          }

          VStack {
            TextField("Search for subreddits to add", text: $searchData.query, onCommit: {
              _ = searchData.search(for: searchData.query)
            })
              .padding(.horizontal)
              .padding(.vertical, 5)
            List {
              ForEach(searchData.suggestions.filter { subreddit in
                !editing.subreddits.contains { $0.name == subreddit.displayName }
              }) { subreddit in
                HStack {
                  Text(subreddit.displayName)
                  Spacer()
                  IllithidButton(label: { Image(systemName: "plus") }) {
                    editing.addSubreddit(subreddit) { result in
                      switch result {
                      case .success:
                        informationBarData.loadMultireddits()
                      case let .failure(error):
                        print("Error adding \(subreddit.displayName) to \(editing.displayName): \(error)")
                      }
                    }
                  }
                }
              }
            }
          }
        }
        .frame(maxHeight: .infinity)
      }
    }
    .frame(minWidth: 1600, minHeight: 900)
  }

  // MARK: Private

  @State private var tapped: Bool = false
}
