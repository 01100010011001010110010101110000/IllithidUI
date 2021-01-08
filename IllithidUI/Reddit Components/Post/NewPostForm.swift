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

import Combine
import SwiftUI

import Alamofire
import Illithid

// MARK: - NewPostForm

struct NewPostForm: View {
  // MARK: Internal

  let navigationSelection: String? = nil

  @Binding var showNewPostForm: Bool

  var body: some View {
    VStack(alignment: .center) {
      HStack {
        Text(model.createPostIn == nil
          ? NSLocalizedString("post.new.subreddit.prompt", comment: "Prompt to select the post's target subreddit")
          : model.createPostIn!.displayNamePrefixed)

        Image(systemName: "chevron.down")
      }
      .font(.title)
      .onTapGesture {
        showSelectionPopover = true
      }
      .popover(isPresented: $showSelectionPopover, arrowEdge: .top) {
        SubredditSelectorView(subredditSelection: $model.createPostIn, isPresented: $showSelectionPopover)
      }
      .padding()

      if let targetSubreddit = model.createPostIn {
        TabView(selection: $model.postType) {
          if targetSubreddit.allowsSelfPosts ?? false {
            SelfPostForm(model: model.selfPostModel)
              .tag(NewPostType.`self`)
              .tabItem {
                Label(title: { Text("post.type.text") },
                      icon: { Image(systemName: "text.bubble") })
              }
              .padding()
          }
          if targetSubreddit.allowsLinkPosts ?? false {
            LinkPostForm(model: model.linkPostModel)
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
        Button(action: {
          switch model.postType {
          case .`self`:
            model.submitSelfPost()
          case .link:
            model.submitLinkPost()
          default:
            return
          }
        }, label: {
          HStack {
            Text("comments.submit")
            if model.posting {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(0.5, anchor: .center)
            } else if case .success = model.result {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            } else if case .failure = model.result {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
            }
          }
        })
          .disabled(!isValid())
      }
      .padding()
    }
    .onReceive(model.$createPostIn, perform: { targetSubreddit in
      if targetSubreddit?.allowsSelfPosts ?? false { model.postType = .`self` }
      else if targetSubreddit?.allowsImagePosts ?? false { model.postType = .image }
      else if targetSubreddit?.allowsLinkPosts ?? false { model.postType = .link }
    })
    .onReceive(model.$result) { result in
      switch result {
      case .success:
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissalDelay) {
          showNewPostForm = false
        }
      default:
        break
      }
    }
    .frame(idealWidth: 1600, idealHeight: 900)
  }

  // MARK: Private

  @StateObject private var model = ViewModel()

  @State private var showSelectionPopover: Bool = false
  private let dismissalDelay: Double = 0.5

  private func isValid() -> Bool {
    switch model.postType {
    case .`self`:
      return model.selfPostModel.isValid()
    case .link:
      return model.linkPostModel.isValid()
    default:
      return false
    }
  }

  private class ViewModel: ObservableObject {
    @Published var createPostIn: Subreddit? = nil
    @Published var postType: NewPostType = .`self`
    @Published var posting: Bool = false
    @Published var result: Result<NewPostResponse, AFError>? = nil

    @Published var linkPostModel: LinkPostForm.ViewModel = .init()
    @Published var selfPostModel: SelfPostForm.ViewModel = .init()

    private var cancelBag: [AnyCancellable] = []

    init() {
      let postingToken = Publishers.MergeMany([linkPostModel.$posting, selfPostModel.$posting])
        .receive(on: RunLoop.main)
        .assign(to: \.posting, on: self)
      let resultToken = Publishers.MergeMany([linkPostModel.$postResult, selfPostModel.$postResult])
        .receive(on: RunLoop.main)
        .assign(to: \.result, on: self)
      cancelBag.append(postingToken)
      cancelBag.append(resultToken)
    }

    func submitSelfPost() {
      guard let target = createPostIn else { return }
      selfPostModel.submitTextPost(in: target)
    }

    func submitLinkPost() {
      guard let target = createPostIn else { return }
      linkPostModel.submitLinkPost(in: target)
    }
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
        if let user = Illithid.shared.accountManager.currentAccount {
          Section(header: Text("user.profile")) {
            // TODO: Get the current account
            Text("u/\(user.name)")
              .tag("__account__")
          }
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
  private let dismissalDelay: Double = 0.5

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
    @Published var posting: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    private var cancelBag: [AnyCancellable] = []

    func isValid() -> Bool {
      !title.isEmpty && !body.isEmpty
    }

    func submitTextPost(in subreddit: Subreddit) {
      posting = true
      let cancelToken = subreddit.submitTextPost(title: title, markdown: body)
        .receive(on: RunLoop.main)
        .sink { [weak self] completion in
          guard let self = self else { return }
          switch completion {
          case .finished:
            break
          case let .failure(error):
            self.postResult = .failure(error)
          }
        } receiveValue: { response in
          self.posting = false
          self.postResult = .success(response)
        }
      cancelBag.append(cancelToken)
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
    @Published var posting: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    private var cancelBag: [AnyCancellable] = []

    func isValid() -> Bool {
      URL(string: linkTo) != nil && !title.isEmpty
    }

    func submitLinkPost(in subreddit: Subreddit) {
      // We validate this before enabling the submit button, but just in case
      guard let url = URL(string: linkTo) else { return }
      posting = true
      let cancelToken = subreddit.submitLinkPost(title: title, linkTo: url)
        .receive(on: RunLoop.main)
        .sink { [weak self] completion in
          guard let self = self else { return }
          switch completion {
          case .finished:
            break
          case let .failure(error):
            self.postResult = .failure(error)
          }
        } receiveValue: { response in
          self.posting = false
          self.postResult = .success(response)
        }
      cancelBag.append(cancelToken)
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
