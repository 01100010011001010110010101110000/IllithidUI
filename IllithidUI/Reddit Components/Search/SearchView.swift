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
  // MARK: Internal

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
            Group {
              Divider()
              HStack {
                Label("Go to user \(searchData.query)", systemImage: "person.crop.circle")
                  .font(.title)
                Spacer()
              }
              .onTapGesture(count: 1, perform: {
                openModal(for: searchData.query)
              })
              Divider()
            }
            .padding(.horizontal)
          }
          if !searchData.suggestions.isEmpty {
            Group {
              HStack {
                Text("Subreddits")
                  .font(.largeTitle)
                Spacer()
              }
              Divider()
              LazyVGrid(columns: subredditColumns) {
                ForEach(searchData.suggestions) { suggestion in
                  SubredditSuggestionLabel(suggestion: suggestion)
                    .onTapGesture(count: 1, perform: {
                      openModal(for: suggestion)
                    })
                }
              }
            }
            .padding(.horizontal)
          }
          if !searchData.posts.isEmpty {
            Group {
              HStack {
                Text("Posts")
                  .font(.largeTitle)
                Spacer()
              }
              Divider()
              ScrollView {
                LazyVGrid(columns: postColumns) {
                  ForEach(searchData.posts) { post in
                    PostClassicRowView(post: post)
                      .onTapGesture(count: 1, perform: {
                        openModal(for: post)
                      })
                  }
                }
              }
            }
            .padding(.horizontal)
          }
        }
      }
      .allowsHitTesting(!haveSelection)
      .disabled(haveSelection)
      .redacted(reason: haveSelection ? .placeholder : [])
      .blur(radius: blur ? 8 : 0)
      .zIndex(1)

      if haveSelection {
        RoundedRectangle(cornerRadius: 8)
          .onMouseGesture(mouseDown: {
            closeModal()
          }, mouseUp: {})
          .foregroundColor(.clear)
          .zIndex(2)
      }

      Group {
        if let subreddit = subredditSelection {
          PostListView(postContainer: subreddit)
        } else if let post = postSelection {
          CommentsView(post: post)
            .background(Color(.windowBackgroundColor))
        } else if let user = userToFind {
          AccountView(name: user)
        }
      }
      .modalModifier()
      .zIndex(3)
    }
  }

  private var haveSelection: Bool {
    subredditSelection != nil
      || postSelection != nil
      || userToFind != nil
  }

  // MARK: Private

  @StateObject private var searchData: SearchData = .init()

  @State private var subredditSelection: Subreddit? = nil
  @State private var postSelection: Post? = nil
  @State private var userToFind: String? = nil
  @State private var blur: Bool = false

  private let subredditColumns: [GridItem] = [
    GridItem(.adaptive(minimum: 320)),
  ]

  private let postColumns: [GridItem] = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]

  private var prompt: String {
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
}

private extension View {
  func modalModifier() -> some View {
    self
      .clipShape(ContainerRelativeShape())
      .padding(20)
      .shadow(radius: 10)
  }
}

// TODO: Pull this modal view with blurred background into something reusable
private extension Animation {
  static let modal: Animation = .interactiveSpring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.25)
  static let blur: Animation = .linear(duration: 0.25)
}
