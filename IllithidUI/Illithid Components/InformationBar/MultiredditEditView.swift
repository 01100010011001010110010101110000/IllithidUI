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
  @EnvironmentObject var informationBarData: InformationBarData
  @ObservedObject var searchData: SearchData
  @State private var tapped: Bool = false

  let editingId: Multireddit.ID

  init(id: Multireddit.ID, searchData: SearchData) {
    editingId = id
    self.searchData = searchData
  }

  var body: some View {
    let editing = informationBarData.multiReddits.first { $0.id == editingId }!
    return VStack {
      VStack {
        Text(editing.displayName)
          .font(.title)
          .padding(.top)
        Text(editing.descriptionMd)
        Divider()
        VSplitView {
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
          TextField("Search for subreddits to add", text: $searchData.query) {
            _ = searchData.search(for: searchData.query)
          }
          .padding([.top], 5)
          List {
            ForEach(searchData.subreddits.filter { subreddit in
              !editing.subreddits.map { $0.name }.contains(subreddit.displayName)
            }) { subreddit in
              HStack {
                Text(subreddit.displayName)
                Spacer()
                IllithidButton(label: "Add to \(editing.displayName)") {
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
    }
    .frame(minWidth: 600, minHeight: 500)
  }
}
