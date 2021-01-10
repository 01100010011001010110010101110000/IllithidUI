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
          : targetDisplayName!)

        Image(systemName: "chevron.down")
      }
      .font(.title)
      .onTapGesture {
        showSelectionPopover = true
      }
      .popover(isPresented: $showSelectionPopover, arrowEdge: .top) {
        SubredditSelectorView(submissionTarget: $model.createPostIn, isPresented: $showSelectionPopover)
      }
      .padding()

      if model.createPostIn != nil {
        TabView(selection: $model.postType) {
          if allowSelfPosts {
            SelfPostForm(model: model.selfPostModel)
              .tag(NewPostType.`self`)
              .tabItem {
                Label(title: { Text("post.type.text") },
                      icon: { Image(systemName: "text.bubble") })
              }
              .padding([.horizontal, .bottom])
          }

          if allowLinkPosts {
            VStack {
              LinkPostForm(model: model.linkPostModel)
              Spacer()
            }
            .tag(NewPostType.link)
            .tabItem {
              Label(title: { Text("post.type.link") },
                    icon: { Image(systemName: "link") })
            }
            .padding(.horizontal)
          }
        }
        .padding(.horizontal)
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
        .disabled(!model.postIsValid)
      }
      .padding()
    }
    .onReceive(model.$createPostIn, perform: { target in
      if let subreddit = targetSubreddit {
        if subreddit.allowsSelfPosts ?? false { model.postType = .`self` }
        else if subreddit.allowsImagePosts ?? false { model.postType = .image }
        else if subreddit.allowsLinkPosts ?? false { model.postType = .link }
      } else {
        model.postType = .`self`
      }
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

  private var targetSubreddit: Subreddit? {
    model.createPostIn as? Subreddit
  }

  private var targetAccount: Account? {
    model.createPostIn as? Account
  }

  private var targetDisplayName: String? {
    targetSubreddit?.displayNamePrefixed ?? targetAccount?.name
  }

  private var allowSelfPosts: Bool {
    targetAccount != nil || (targetSubreddit?.allowsSelfPosts ?? false)
  }

  private var allowLinkPosts: Bool {
    targetAccount != nil || (targetSubreddit?.allowsLinkPosts ?? false)
  }

  private class ViewModel: ObservableObject {
    @Published var createPostIn: PostAcceptor? = nil
    @Published var postType: NewPostType = .`self`
    @Published var postIsValid: Bool = false
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

      // These two subscribers update the validity of the submission whenever:
      // * A tab's fields are updated
      // * The tab is changed
      let validityToken = Publishers.MergeMany([linkPostModel.$isValid, selfPostModel.$isValid])
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          self?.calculateSubmissionValidity()
        }
      let submissionTypeToken = $postType
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          self?.calculateSubmissionValidity()
        }
      
      cancelBag.append(submissionTypeToken)
      cancelBag.append(validityToken)
      cancelBag.append(postingToken)
      cancelBag.append(resultToken)
    }

    private func calculateSubmissionValidity() {
      switch self.postType {
      case .`self`:
        self.postIsValid = self.selfPostModel.isValid
      case .link:
        self.postIsValid = self.linkPostModel.isValid
      default:
        break
      }
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
  @Binding var submissionTarget: PostAcceptor?
  @Binding var isPresented: Bool

  var body: some View {
    VStack {
      // TODO: Add a search bar
      List(selection: $subredditId) {
        if let user = Illithid.shared.accountManager.currentAccount {
          Section(header: Text("user.profile")) {
            // TODO: Fetch account avatar if present
            Label(
              title: { Text("u/\(user.name)") },
              icon: { Image(systemName: "person.crop.circle") }
            )
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
      submissionTarget = findSelection()
    }
  }

  // MARK: Private

  @State private var subredditId: String?
  private let dismissalDelay: Double = 0.5

  private func findSelection() -> PostAcceptor? {
    // TODO: Support user subreddit, moderated subreddits, etc
    if subredditId == "__account__" {
      return Illithid.shared.accountManager.currentAccount
    } else if let subreddit = informationBarData.subscribedSubreddits.first(where: { $0.id == subredditId }) {
      return subreddit
    } else { return nil }
  }
}

// MARK: - SelfPostForm

private struct SelfPostForm: View {
  class ViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var body: String = ""
    @Published var posting: Bool = false
    @Published var isValid: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    init() {
      let validityToken = Publishers.Merge($title, $body)
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          self.isValid = !self.body.isEmpty && !self.title.isEmpty
        }
      cancelBag.append(validityToken)
    }

    private var cancelBag: [AnyCancellable] = []

    func submitTextPost(in acceptor: PostAcceptor) {
      posting = true
      let cancelToken = acceptor.submitSelfPost(title: title, markdown: body)
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
  class ViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var linkTo: String = ""
    @Published var posting: Bool = false
    @Published var isValid: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    init() {
      let validityToken = Publishers.Merge($title, $linkTo)
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          self.isValid = !self.title.isEmpty && !self.linkTo.isEmpty
            && self.detector.firstMatch(in: self.linkTo, range: NSRange(location: 0, length: self.linkTo.utf16.count)) != nil
        }
      cancelBag.append(validityToken)
    }

    private var cancelBag: [AnyCancellable] = []
    private let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    func submitLinkPost(in acceptor: PostAcceptor) {
      // We validate this before enabling the submit button, but just in case
      guard let url = URL(string: linkTo) else { return }
      posting = true
      let cancelToken = acceptor.submitLinkPost(title: title, linkTo: url)
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
