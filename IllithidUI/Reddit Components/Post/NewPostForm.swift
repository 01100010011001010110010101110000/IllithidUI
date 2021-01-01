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
        Text(createPostIn == nil
          ? NSLocalizedString("post.new.subreddit.prompt", comment: "Prompt to select the post's target subreddit")
          : createPostIn!.displayNamePrefixed)

        Image(systemName: "chevron.down")
      }
      .font(.title)
      .onTapGesture {
        showSelectionPopover = true
      }
      .popover(isPresented: $showSelectionPopover, arrowEdge: .top) {
        SubredditSelectorView(subredditSelection: $createPostIn, isPresented: $showSelectionPopover)
      }
      .padding()

      if let targetSubreddit = createPostIn {
        TabView(selection: $postType) {
          if targetSubreddit.allowsSelfPosts ?? false {
            SelfPostForm(model: selfPostModel)
              .tag(NewPostType.`self`)
              .tabItem {
                Label(title: { Text("post.type.text") },
                      icon: { Image(systemName: "text.bubble") })
              }
              .padding()
          }
          if targetSubreddit.allowsLinkPosts ?? false {
            LinkPostForm(model: linkPostModel)
              .tag(NewPostType.link)
              .tabItem {
                Label(title: { Text("post.type.link") },
                      icon: { Image(systemName: "link") })
              }
              .padding(.horizontal)
          }
        }
      } else {
        Spacer()
      }

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
        Button("post.submit") {}
          .disabled(!isValid())
      }
      .padding()
    }
    .onChange(of: createPostIn, perform: { targetSubreddit in
      if targetSubreddit?.allowsSelfPosts ?? false { postType = .`self` }
      else if targetSubreddit?.allowsImagePosts ?? false { postType = .image }
      else if targetSubreddit?.allowsLinkPosts ?? false { postType = .link }
    })
    .frame(idealWidth: 1600, idealHeight: 900)
  }

  // MARK: Private

  @StateObject private var selfPostModel: SelfPostForm.ViewModel = .init()
  @StateObject private var linkPostModel: LinkPostForm.ViewModel = .init()

  @State private var showSelectionPopover: Bool = false
  @State private var createPostIn: Subreddit? = nil
  @State private var postType: NewPostType = .`self`

  private func isValid() -> Bool {
    switch postType {
    case .`self`:
      return selfPostModel.isValid()
    case .image:
      return false
    case .link:
      return linkPostModel.isValid()
    }
  }
}

private extension NewPostForm {
  enum NewPostType {
    case `self`
    case image
    case link
  }
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
    if let subreddit = informationBarData.subscribedSubreddits.first(where: { $0.id == subredditId }) {
      return subreddit
    } else { return nil }
  }
}

// MARK: - SubmissionViewModel

protocol SubmissionViewModel: ObservableObject {
  func isValid() -> Bool
}

// MARK: - SelfPostForm

private struct SelfPostForm: View {
  class ViewModel: SubmissionViewModel {
    @Published var title: String = ""
    @Published var body: String = ""

    func isValid() -> Bool {
      !title.isEmpty && !body.isEmpty
    }
  }

  @ObservedObject var model: SelfPostForm.ViewModel

  var body: some View {
    VStack {
      TextField("post.new.title", text: $model.title)
        .font(.title)
      TextEditor(text: $model.body)
        .font(.system(size: 18))
    }
  }
}

// MARK: - LinkPostForm

private struct LinkPostForm: View {
  class ViewModel: SubmissionViewModel {
    @Published var title: String = ""
    @Published var linkTo: String = ""

    func isValid() -> Bool {
      URL(string: linkTo) != nil && !title.isEmpty
    }
  }

  @ObservedObject var model: LinkPostForm.ViewModel

  var body: some View {
    VStack {
      TextField("post.new.title", text: $model.title)
        .font(.title)
      TextField("post.new.link-to", text: $model.linkTo)
        .font(.title)
    }
  }
}
