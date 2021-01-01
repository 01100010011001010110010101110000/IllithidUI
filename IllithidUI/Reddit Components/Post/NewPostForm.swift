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

// MARK: - NewPostForm

struct NewPostForm: View {
  // MARK: Internal

  let navigationSelection: String? = nil

  @Binding var showNewPostForm: Bool

  var body: some View {
    VStack(alignment: .center) {
      HStack {
        Text("post.new.subreddit.prompt")
        Image(systemName: "chevron.down")
      }
      .onTapGesture {
        showSelectionPopover = true
      }
      .popover(isPresented: $showSelectionPopover, arrowEdge: .top) {
        SubredditSelectorView(subredditSelection: $createPostIn, isPresented: $showSelectionPopover)
      }
      .padding()

      TabView {
        TextEditor(text: $postBody)
          .frame(idealWidth: 1600, idealHeight: 900)
          .tabItem {
            Label(title: { Text("post.type.text") }, icon: { Image(systemName: "text.bubble") })
          }
      }
      .disabled(createPostIn == nil)

      HStack {
        Button(action: {
          withAnimation {
            showNewPostForm = false
          }
        }, label: {
          Text("cancel")
        })
          .keyboardShortcut(.cancelAction)
        Spacer()
      }
      .padding()
    }
  }

  // MARK: Private

  @State private var showSelectionPopover: Bool = false
  @State private var createPostIn: Subreddit? = nil

  @State private var postBody: String = ""
}

// MARK: - SubredditSelectorView

private struct SubredditSelectorView: View {
  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData
  @Binding var subredditSelection: Subreddit?
  @Binding var isPresented: Bool

  var body: some View {
    VStack {
      // TODO: Add a search bar
      List(selection: $subredditId) {
        Section(header: Text("user.profile")) {
          // TODO: Get the current account
          Text("CURRENT USER PLACEHOLDER")
            .tag("__account__")
        }

        Section(header: Text("subreddits.subscribed")) {
          ForEach(informationBarData.subscribedSubreddits) { subreddit in
            HStack {
              SubredditIcon(subreddit: subreddit)
                .frame(width: 24, height: 24)
              Text(subreddit.displayName)
            }
          }
        }
      }
    }
    .onChange(of: subredditId) { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + dismissalDelay) {
        isPresented = false
      }
      subredditSelection = findSelection()
    }
  }

  // MARK: Private

  @State private var subredditId: String?
  private let dismissalDelay: Double = 0.4
  private func findSelection() -> Subreddit? {
    // TODO: Support user subreddit, moderated subreddits, etc
    if let subreddit = informationBarData.subscribedSubreddits.first { $0.id == subredditId } {
      return subreddit
    } else { return nil }
  }
}
