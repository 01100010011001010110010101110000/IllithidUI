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

// MARK: - SearchView

struct SearchView: View {
  @StateObject var searchData: SearchData = .init()

  @State private var subredditSelection: Subreddit? = nil
  @State private var postSelection: Post? = nil
  @State private var userToFind: String? = nil
  @State private var blur: Bool = false

  let columns: [GridItem] = [
    GridItem(.adaptive(minimum: 320)),
  ]

  var prompt: String {
    if searchData.query.isEmpty { return "Make a search" }
    else if searchData.suggestions.isEmpty { return "No subreddits found" }
    else { return "Open a subreddit" }
  }

  private func openModal(for subreddit: Subreddit) {
    withAnimation(.modal) { subredditSelection = subreddit }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = true }
    }
  }

  private func openModal(for post: Post) {
    withAnimation(.modal) { postSelection = post }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = true }
    }
  }

  private func openModal(for user: String) {
    withAnimation(.modal) { userToFind = user }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = true }
    }
  }

  private func closeModal() {
    withAnimation(.modal) {
      subredditSelection = nil
      postSelection = nil
      userToFind = nil
    }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = false }
    }
  }

  var body: some View {
    ZStack {
      VStack {
        TextField("Search Reddit", text: $searchData.query, onCommit: {
          // Allows the user to force a search for a string shorter than 3 characters
          _ = self.searchData.search(for: self.searchData.query)
        })
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding()

        ScrollView {
          if !searchData.query.isEmpty {
            HStack {
              Label("Go to user \(searchData.query)", systemImage: "person.crop.circle")
              Spacer()
            }
            .padding(.horizontal)
            .onTapGesture(count: 1, perform: {
              openModal(for: searchData.query)
            })
          }
          Divider()
          Text("Subreddits")
            .font(.title)
          Divider()
          LazyVGrid(columns: columns) {
            ForEach(searchData.suggestions) { suggestion in
              SubredditSuggestionLabel(suggestion: suggestion)
                .onTapGesture(count: 1, perform: {
                  openModal(for: suggestion)
                })
            }
          }
          .padding(10)
          Text("Posts")
            .font(.title)
          Divider()
          LazyVGrid(columns: columns) {
            ForEach(searchData.posts) { post in
              PostClassicRowView(post: post)
                .onTapGesture(count: 1, perform: {
                  openModal(for: post)
                })
            }
          }
        }
      }
      .allowsHitTesting(subredditSelection == nil && postSelection == nil && userToFind == nil)
      .disabled(subredditSelection != nil || postSelection != nil || userToFind != nil)
      .blur(radius: blur ? 8 : 0)
      .zIndex(1)

      if subredditSelection != nil
        || postSelection != nil
        || userToFind != nil {
        RoundedRectangle(cornerRadius: 8)
          .onMouseGesture(mouseDown: {
            closeModal()
          }, mouseUp: {})
          .foregroundColor(.clear)
          .zIndex(2)
      }

      if let subreddit = subredditSelection {
        PostListView(postContainer: subreddit)
          .clipShape(ContainerRelativeShape())
          .padding(20)
          .shadow(radius: 10)
          .zIndex(3)
      } else if let post = postSelection {
        CommentsView(post: post)
          .clipShape(ContainerRelativeShape())
          .background(Color(.windowBackgroundColor))
          .padding(20)
          .shadow(radius: 10)
          .zIndex(3)
      } else if let user = userToFind {
        AccountView(name: user)
          .clipShape(ContainerRelativeShape())
          .padding(20)
          .shadow(radius: 10)
          .zIndex(3)
      }
    }
  }
}

// TODO: Pull this modal view with blurred background into something reusable
private extension Animation {
  static let modal: Animation = .interactiveSpring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.25)
  static let blur: Animation = .linear(duration: 0.25)
}
