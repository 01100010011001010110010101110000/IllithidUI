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
    toEdit = multireddit
  }

  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData
  let toEdit: Multireddit

  var editing: Multireddit {
    informationBarData.multireddits.first { $0.id == toEdit.id } ?? toEdit
  }

  var body: some View {
    VStack {
      VStack {
        Text(editing.displayName)
          .font(.title)
          .padding(.top)
        Text(editing.descriptionMd)
        Divider()
        HSplitView {
          List(selection: $currentSubscription) {
            ForEach(editing.subreddits) { subreddit in
              HStack {
                Text(subreddit.name)
                Spacer()
                Button(action: {
                  removeSubreddit(subreddit)
                }, label: {
                  Image(systemName: "trash")
                    .foregroundColor(.red)
                })
              }
            }
            .onDelete { indexSet in
              indexSet.forEach { index in
                let subreddit = editing.subreddits[index]
                removeSubreddit(subreddit)
              }
            }
          }

          VStack {
            TextField("Search for subreddits to add", text: $searchData.query, onCommit: {
              guard !searchData.query.isEmpty else { return }
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
                  Button(action: {
                    addSubreddit(subreddit)
                  }, label: {
                    Image(systemName: "plus")
                      .foregroundColor(.accentColor)
                  })
                }
              }
            }
          }
        }
        .frame(maxHeight: .infinity)
      }
    }
    .frame(idealWidth: 1600, idealHeight: 900)
  }

  // MARK: Private

  @StateObject private var searchData: SearchData = .init(for: [.subreddit])
  @State private var currentSubscription: String? = nil

  @State private var tapped: Bool = false

  private func addSubreddit(_ subreddit: Subreddit) {
    editing.addSubreddit(subreddit) { result in
      switch result {
      case .success:
        informationBarData.loadMultireddits()
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Error adding \(subreddit.displayName) to \(editing.displayName): \(error)")
      }
    }
  }

  private func removeSubreddit(_ subreddit: Multireddit.MultiSubreddit) {
    editing.removeSubreddit(subreddit) { result in
      switch result {
      case .success:
        informationBarData.loadMultireddits()
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Error removing \(subreddit.name) from \(editing.displayName): \(error)")
      }
    }
  }
}
