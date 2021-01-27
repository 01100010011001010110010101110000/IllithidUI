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
import UniformTypeIdentifiers

import Alamofire
import Illithid
import SDWebImageSwiftUI

// MARK: - NewPostForm

struct NewPostForm: View {
  // MARK: Internal

  let navigationSelection: String? = nil

  @Binding var showNewPostForm: Bool

  var body: some View {
    VStack(alignment: .center) {
      selectionHeader

      if let acceptor = model.createPostIn {
        TabView(selection: $model.postType) {
          if acceptor.permitsSelfPosts {
            SelfPostForm(model: model.selfPostModel)
              .tag(NewPostType.`self`)
              .tabItem {
                Label(title: { Text("post.type.text") },
                      icon: { Image(systemName: "text.bubble") })
              }
              .padding([.horizontal, .bottom])
          }

          // In the current Reddit API implementation, if image posts are allowed, so are GIFs
          if acceptor.permitsImagePosts {
            ImageGifPostForm(for: acceptor, model: model.imagePostModel)
              .tag(NewPostType.image)
              .tabItem {
                Label(title: { Text("post.type.image.and.gif") },
                      icon: { Image(systemName: "photo.on.rectangle.angled") })
              }
              .padding([.horizontal, .bottom])
          }

          if acceptor.permitsLinkPosts {
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

      formControl
    }
    .onReceive(model.$createPostIn, perform: { target in
      if let acceptor = target {
        if acceptor.permitsSelfPosts { model.postType = .`self` }
        else if acceptor.permitsImagePosts { model.postType = .image }
        else if acceptor.permitsLinkPosts { model.postType = .link }
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

  private class ViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
      let postingToken = Publishers.MergeMany([linkPostModel.$posting, selfPostModel.$posting, imagePostModel.$posting])
        .receive(on: RunLoop.main)
        .assign(to: \.posting, on: self)
      let resultToken = Publishers.MergeMany([linkPostModel.$postResult, selfPostModel.$postResult, imagePostModel.$postResult])
        .receive(on: RunLoop.main)
        .assign(to: \.result, on: self)

      // These two subscribers update the validity of the submission whenever:
      // * A tab's fields are updated
      // * The tab is changed
      let validityToken = Publishers.MergeMany([linkPostModel.$isValid, selfPostModel.$isValid, imagePostModel.$isValid])
        .combineLatest($postType)
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _ in
          self?.calculateSubmissionValidity()
        }

      cancelBag.append(validityToken)
      cancelBag.append(postingToken)
      cancelBag.append(resultToken)
    }

    // MARK: Internal

    @Published var createPostIn: PostAcceptor? = nil
    @Published var postType: NewPostType = .`self`
    @Published var postIsValid: Bool = false
    @Published var posting: Bool = false
    @Published var result: Result<NewPostResponse, AFError>? = nil

    @Published var linkPostModel = LinkPostForm.ViewModel()
    @Published var selfPostModel = SelfPostForm.ViewModel()
    @Published var imagePostModel = ImageGifPostForm.ViewModel()

    func submitSelfPost() {
      guard let target = createPostIn else { return }
      selfPostModel.submitTextPost(to: target)
    }

    func submitLinkPost() {
      guard let target = createPostIn else { return }
      linkPostModel.submitLinkPost(to: target)
    }

    func submitImagePost() {
      guard let target = createPostIn else { return }
      imagePostModel.submit(to: target)
    }

    // MARK: Private

    private var cancelBag: [AnyCancellable] = []

    private func calculateSubmissionValidity() {
      switch postType {
      case .`self`:
        postIsValid = selfPostModel.isValid
      case .link:
        postIsValid = linkPostModel.isValid
      case .image:
        postIsValid = imagePostModel.isValid
      default:
        break
      }
    }
  }

  @StateObject private var model = ViewModel()

  @State private var showSelectionPopover: Bool = false
  private let dismissalDelay: Double = 0.5

  private var selectionHeader: some View {
    HStack {
      Text(model.createPostIn == nil
        ? NSLocalizedString("post.new.subreddit.prompt", comment: "Prompt to select the post's target subreddit")
        : model.createPostIn!.displayName)
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
  }

  private var formControl: some View {
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
        case .image:
          model.submitImagePost()
        default:
          return
        }
      }, label: {
        HStack {
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
          Text("post.submit")
        }
      })
        .disabled(!model.postIsValid)
    }
    .padding()
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
    // MARK: Lifecycle

    init() {
      let validityToken = Publishers.Merge($title, $body)
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          self.isValid = !self.body.isEmpty && !self.title.isEmpty
        }
      cancelBag.append(validityToken)
    }

    // MARK: Internal

    @Published var title: String = ""
    @Published var body: String = ""
    @Published var posting: Bool = false
    @Published var isValid: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    func submitTextPost(to acceptor: PostAcceptor) {
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
          self.posting = false
        } receiveValue: { [weak self] response in
          self?.postResult = .success(response)
        }
      cancelBag.append(cancelToken)
    }

    // MARK: Private

    private var cancelBag: [AnyCancellable] = []
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
    // MARK: Lifecycle

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

    // MARK: Internal

    @Published var title: String = ""
    @Published var linkTo: String = ""
    @Published var posting: Bool = false
    @Published var isValid: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    func submitLinkPost(to acceptor: PostAcceptor) {
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
          self.posting = false
        } receiveValue: { [weak self] response in
          self?.postResult = .success(response)
        }
      cancelBag.append(cancelToken)
    }

    // MARK: Private

    private var cancelBag: [AnyCancellable] = []
    private let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
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

// MARK: - ImageGifPostForm

private struct ImageGifPostForm: View {
  // MARK: Lifecycle

  init(for acceptor: PostAcceptor, model: ViewModel) {
    self.acceptor = acceptor
    self.model = model
  }

  // MARK: Internal

  class ViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
      let validityToken = Publishers.CombineLatest($title, $selectedItems)
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _ in
          guard let self = self else { return }
          self.isValid = !self.title.isEmpty && !self.selectedItems.isEmpty
        }
      cancelBag.append(validityToken)
    }

    // MARK: Internal

    @Published var isValid: Bool = false
    @Published var posting: Bool = false
    @Published var presentImageSelector: Bool = false
    @Published var title: String = ""
    @Published var selectedItems: [URL] = []
    @Published var postResult: Result<NewPostResponse, AFError>? = nil
    @Published var galleryModel = GalleryCarousel.ViewModel()

    func submit(to acceptor: PostAcceptor) {
      if selectedItems.count > 1 {
        submitGalleryPost(to: acceptor)
      } else {
        submitImagePost(to: acceptor)
      }
    }

    // MARK: Private

    private var cancelBag: [AnyCancellable] = []

    private func submitImagePost(to acceptor: PostAcceptor) {
      let illithid: Illithid = .shared
      guard let url = selectedItems.first else { return }

      posting = true
      let uploadToken = illithid
        .uploadMedia(fileUrl: url)
        .flatMap { lease, _ in
          Publishers.Zip(illithid.receiveUploadResponse(lease: lease),
                         illithid.submit(kind: .image, subredditDisplayName: acceptor.uploadTarget,
                                         title: self.title, linkTo: lease.lease.retrievalUrl))
        }
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { [weak self] completion in
          switch completion {
          case .finished:
            break
          case let .failure(error):
            self?.postResult = .failure(error)
            illithid.logger.errorMessage("Failed to submit image post: \(error)")
          }
          self?.posting = false
        }) { [weak self] _, postResponse in
          self?.postResult = .success(postResponse)
          illithid.logger.debugMessage("Successfully submitted image post: \(postResponse.json.data.url?.absoluteString ?? "NO ASSOCIATED URL")")
        }
      cancelBag.append(uploadToken)
    }

    private func submitGalleryPost(to acceptor: PostAcceptor) {
      let illithid: Illithid = .shared

      posting = true
      let uploadToken = illithid.submitGalleryPost(subredditDisplayName: acceptor.uploadTarget, title: title, galleryItems: galleryModel.galleryItems())
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { [weak self] completion in
          switch completion {
          case .finished:
            break
          case let .failure(error):
            self?.postResult = .failure(error)
            illithid.logger.errorMessage("Failed to submit gallery post: \(error)")
          }
          self?.posting = false
        }, receiveValue: { [weak self] postResponse in
          self?.postResult = .success(postResponse)
          illithid.logger.debugMessage("Successfully submitted gallery post: \(postResponse.json.data.url?.absoluteString ?? "NO ASSOCIATED URL")")
        })
      cancelBag.append(uploadToken)
    }
  }

  let acceptor: PostAcceptor
  @ObservedObject var model: Self.ViewModel

  var body: some View {
    VStack {
      TextField("post.new.title", text: $model.title)
        .font(.title)
        .fileImporter(isPresented: $model.presentImageSelector, allowedContentTypes: allowedContentTypes, allowsMultipleSelection: allowsMultipleItems) { result in
          switch result {
          case let .success(urls):
            // TODO: Append to URL list instead of overwriting, while respecting 20 item max, if user wants to add more gallery items after first selection
            if urls.count > maxGalleryItems {
              model.selectedItems = Array(urls[..<maxGalleryItems])
              showTooManyItemsAlert = true
            } else {
              model.selectedItems = urls
            }
          case let .failure(error):
            Illithid.shared.logger.errorMessage("Failed to select image: \(error)")
          }
          model.presentImageSelector = false
        }
        .alert(isPresented: $showTooManyItemsAlert) {
          Alert(title: Text("too.many.gallery.items.title"), message: Text("too.many.gallery.items.body"))
        }
      if acceptor.permitsGalleryPosts, !model.selectedItems.isEmpty {
        GalleryCarousel(model: model.galleryModel, urls: $model.selectedItems)
      } else if acceptor.permitsImagePosts, let imageUrl = model.selectedItems.first {
        AnimatedImage(url: imageUrl, isAnimating: .constant(true))
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 120, height: 120)
      } else {
        Spacer()
        Button(action: { model.presentImageSelector = true }, label: {
          Text("choose.image")
        })
          .keyboardShortcut("o")
        Spacer()
      }
    }
  }

  // MARK: Private

  @State private var showTooManyItemsAlert: Bool = false

  private let maxGalleryItems = Illithid.maximumGalleryItems

  private var allowsMultipleItems: Bool {
    acceptor.permitsGalleryPosts
  }

  private var allowedContentTypes: [UTType] {
    var result: [UTType] = []

    if acceptor.permitsImagePosts {
      result.append(contentsOf: [.png, .jpeg])
    }
    if acceptor.permitsGifPosts {
      result.append(.gif)
    }

    return result
  }
}

// MARK: - GalleryCarousel

private struct GalleryCarousel: View {
  // MARK: Lifecycle

  init(model: Self.ViewModel, urls imageUrls: Binding<[URL]>) {
    self.model = model
    _imageUrls = imageUrls
  }

  // MARK: Internal

  class ViewModel: ObservableObject {
    @Published var imageTitles: [URL: String] = [:]
    @Published var imageOutboundUrls: [URL: String] = [:]
    @Published var imageIds: [URL: String] = [:]

    func titleBinding(for key: URL) -> Binding<String> {
      .init(get: {
        self.imageTitles[key, default: ""]
      }, set: { newValue in
        self.imageTitles[key] = newValue
      })
    }

    func outboundBinding(for key: URL) -> Binding<String> {
      .init(get: {
        self.imageOutboundUrls[key, default: ""]
      }, set: { newValue in
        self.imageOutboundUrls[key] = newValue
      })
    }

    func galleryItems() -> [GalleryDataItem] {
      imageIds.map { url, mediaId in
        GalleryDataItem(mediaId: mediaId, caption: imageTitles[url], outboundUrl: URL(string: imageOutboundUrls[url, default: ""]))
      }
    }

    func removeItem(withUrl url: URL) {
      imageTitles.removeValue(forKey: url)
      imageOutboundUrls.removeValue(forKey: url)
      imageIds.removeValue(forKey: url)
    }
  }

  @ObservedObject var model: Self.ViewModel
  @Binding var imageUrls: [URL]

  var body: some View {
    VStack {
      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(imageUrls, id: \.absoluteString) { url in
            UploadImagePreview(imageUrl: url, onRemoval: { urlToDelete in
              withAnimation {
                if selected == url { selected = nil }
                imageUrls.removeAll(where: { $0 == urlToDelete })
                model.removeItem(withUrl: urlToDelete)
              }
            }, onUpload: { lease in
              model.imageIds[url] = lease.asset.assetId
            })
              .background(selected == url ? Color(.controlColor) : Color.clear)
              .onTapGesture {
                if selected == url {
                  selected = nil
                } else {
                  selected = url
                }
              }
          }
        }
      }
      .frame(height: 260)

      if let selectedImage = selected {
        HStack {
          AnimatedImage(url: selectedImage, isAnimating: .constant(true))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 480, height: 360)

          Divider()

          VStack {
            TextField("gallery.item.caption", text: model.titleBinding(for: selectedImage))
              .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("gallery.item.link", text: model.outboundBinding(for: selectedImage))
              .textFieldStyle(RoundedBorderTextFieldStyle())
            Spacer()
          }
          .frame(minWidth: 200)
        }
      } else {
        Spacer()
      }
    }
  }

  // MARK: Private

  @State private var selected: URL? = nil
}

// MARK: - UploadImagePreview

private struct UploadImagePreview: View {
  // MARK: Lifecycle

  init(imageUrl: URL, onRemoval: @escaping (URL) -> Void, onUpload: @escaping (AssetUploadLease) -> Void) {
    self.imageUrl = imageUrl
    self.onRemoval = onRemoval
    _model = .init(wrappedValue: Self.ViewModel(onUpload: onUpload))
  }

  // MARK: Internal

  class ViewModel: ObservableObject {
    // MARK: Lifecycle

    init(onUpload: @escaping (AssetUploadLease) -> Void) { self.onUpload = onUpload }

    // MARK: Internal

    @Published var uploadResult: Result<AssetUploadLease, AFError>? = nil
    var onUpload: (AssetUploadLease) -> Void

    func upload(image: URL) {
      uploadToken = Illithid.shared.uploadMedia(fileUrl: image)
        .sink(receiveCompletion: { [weak self] completion in
          switch completion {
          case .finished:
            break
          case let .failure(error):
            self?.uploadResult = .failure(error)
          }
        }, receiveValue: { [weak self] lease, _ in
          self?.uploadResult = .success(lease)
          self?.onUpload(lease)
        })
    }

    // MARK: Private

    private var uploadToken: AnyCancellable?
  }

  let imageUrl: URL
  let onRemoval: (URL) -> Void

  var body: some View {
    // TODO: Calculate correct widths
    GroupBox {
      AnimatedImage(url: imageUrl, isAnimating: .constant(false))
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 240, height: 240)
        .onHover { hovering in
          isHovering = hovering
        }
        .onAppear {
          model.upload(image: imageUrl)
        }
        .loadingScreen(isLoading: model.uploadResult == nil, dimBackground: true)
        .overlay(
          Button(action: {
            onRemoval(imageUrl)
          }, label: {
            Image(systemName: "xmark.circle.fill")
          })
            .keyboardShortcut(.delete, modifiers: .none)
            .opacity(isHovering ? 1 : 0), alignment: .topLeading
        )
        .animation(.default)
    }
  }

  // MARK: Private

  @State private var isHovering: Bool = false
  @StateObject private var model: Self.ViewModel
}
