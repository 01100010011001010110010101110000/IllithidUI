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

import AVFoundation
import Combine
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

import Alamofire
import Illithid
import SDWebImageSwiftUI

// MARK: - NewPostForm

struct NewPostForm: View {
  // MARK: Lifecycle

  init(isPresented: Binding<Bool>) {
    _showNewPostForm = isPresented
  }

  // MARK: Internal

  let navigationSelection: String? = nil

  @Binding var showNewPostForm: Bool

  var body: some View {
    VStack(alignment: .center) {
      selectionHeader

      if let acceptor = model.createPostIn {
        TabView(selection: $model.postType) {
          if acceptor.permitsSelfPosts {
            SelfPostForm(title: $model.title, model: model.selfPostModel)
              .tag(NewPostType.`self`)
              .tabItem {
                Label(title: { Text("post.type.text") },
                      icon: { Image(systemName: "text.bubble") })
              }
              .padding([.horizontal, .bottom])
          }

          // In the current Reddit API implementation, if image posts are allowed, so are GIFs
          if acceptor.permitsImagePosts {
            ImageGifPostForm(for: acceptor, title: $model.title, model: model.imagePostModel)
              .tag(NewPostType.image)
              .tabItem {
                Label(title: { Text("post.type.image.and.gif") },
                      icon: { Image(systemName: "photo.on.rectangle.angled") })
              }
              .padding([.horizontal, .bottom])
          }

          if acceptor.permitsLinkPosts {
            VStack {
              LinkPostForm(title: $model.title, model: model.linkPostModel)
              Spacer()
            }
            .tag(NewPostType.link)
            .tabItem {
              Label(title: { Text("post.type.link") },
                    icon: { Image(systemName: "link") })
            }
            .padding(.horizontal)
          }

          if acceptor.permitsVideoPosts {
            VStack {
              VideoPostForm(title: $model.title, model: model.videoPostModel)
              Spacer()
            }
            .tag(NewPostType.video)
            .tabItem {
              Label(title: { Text("post.type.video") },
                    icon: { Image(systemName: "video") })
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
    .textFieldStyle(RoundedBorderTextFieldStyle())
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
      let postingToken = Publishers.MergeMany([linkPostModel.$posting, selfPostModel.$posting,
                                               imagePostModel.$posting, videoPostModel.$posting])
        .receive(on: RunLoop.main)
        .assign(to: \.posting, on: self)
      let resultToken = Publishers.MergeMany([linkPostModel.$postResult, selfPostModel.$postResult,
                                              imagePostModel.$postResult, videoPostModel.$postResult])
        .receive(on: RunLoop.main)
        .assign(to: \.result, on: self)

      // These two subscribers update the validity of the submission whenever:
      // * A tab's fields are updated
      // * The tab is changed
      let validityToken = Publishers.MergeMany([linkPostModel.$isValid, selfPostModel.$isValid,
                                                imagePostModel.$isValid, videoPostModel.$isValid])
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

    @Published var title: String = ""
    @Published var createPostIn: PostAcceptor? = nil
    @Published var postType: NewPostType = .`self`
    @Published var postIsValid: Bool = false
    @Published var posting: Bool = false
    @Published var result: Result<NewPostResponse, AFError>? = nil

    @Published var linkPostModel = LinkPostForm.ViewModel()
    @Published var selfPostModel = SelfPostForm.ViewModel()
    @Published var imagePostModel = ImageGifPostForm.ViewModel()
    @Published var videoPostModel = VideoPostForm.ViewModel()

    func submit() {
      guard let target = createPostIn else { return }
      switch postType {
      case .`self`:
        selfPostModel.submitTextPost(titled: title, to: target)
      case .link:
        linkPostModel.submitLinkPost(titled: title, to: target)
      case .image:
        imagePostModel.submit(titled: title, to: target)
      case .video:
        videoPostModel.submit(titled: title, to: target)
      default:
        return
      }
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
      case .video:
        postIsValid = videoPostModel.isValid
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

  private var cancelButton: some View {
    Button(action: {
      withAnimation {
        showNewPostForm = false
      }
    }, label: {
      Text("cancel")
    })
      .keyboardShortcut(.cancelAction)
  }

  private var submitButton: some View {
    Button(action: {
      model.submit()
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
      .disabled(!model.postIsValid && !model.title.isEmpty)
  }

  private var formControl: some View {
    HStack {
      cancelButton
      Spacer()
      HStack {
        if case .video = model.postType {
          Toggle(isOn: $model.videoPostModel.postAsGif, label: {
            Text("post.video.upload.as.gif")
          })
            .keyboardShortcut("g", modifiers: .option)
            .help("post.video.upload.as.gif.description")
        }
        submitButton
      }
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
      TextField("search.prompt", text: $searchText)
        .font(.title2)
        .padding([.top, .horizontal], 5)
      List(selection: $subredditId) {
        if let user = Illithid.shared.accountManager.currentAccount,
           searchText.isEmpty || (user.name.range(of: searchText, options: .caseInsensitive) != nil) {
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
          ForEach(filteredSubscriptions) { subreddit in
            HStack {
              SubredditIcon(subreddit: subreddit)
                .frame(width: 24, height: 24)
              Text(subreddit.displayName)
            }
          }
        }
      }
    }
    .frame(minWidth: 200, minHeight: 400)
    .onChange(of: subredditId) { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + dismissalDelay) {
        isPresented = false
      }
      submissionTarget = findSelection()
    }
  }

  // MARK: Private

  @State private var subredditId: String?
  @State private var searchText: String = ""
  private let dismissalDelay: Double = 0.3

  private var filteredSubscriptions: [Subreddit] {
    guard !searchText.isEmpty else { return informationBarData.subscribedSubreddits }
    return informationBarData.subscribedSubreddits
      .filter { $0.displayName.range(of: searchText, options: .caseInsensitive) != nil }
  }

  private func findSelection() -> PostAcceptor? {
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
      let validityToken = $body
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          self.isValid = !self.body.isEmpty
        }
      cancelBag.append(validityToken)
    }

    // MARK: Internal

    @Published var body: String = ""
    @Published var posting: Bool = false
    @Published var isValid: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    func submitTextPost(titled title: String, to acceptor: PostAcceptor) {
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

  @Binding var title: String
  @ObservedObject var model: SelfPostForm.ViewModel

  var body: some View {
    VStack {
      TextField("post.new.title", text: $title)
        .font(.title2)
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
      let validityToken = $linkTo
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          self.isValid = !self.linkTo.isEmpty
            && self.detector.firstMatch(in: self.linkTo, range: NSRange(location: 0, length: self.linkTo.utf16.count)) != nil
        }
      cancelBag.append(validityToken)
    }

    // MARK: Internal

    @Published var linkTo: String = ""
    @Published var posting: Bool = false
    @Published var isValid: Bool = false
    @Published var postResult: Result<NewPostResponse, AFError>? = nil

    func submitLinkPost(titled title: String, to acceptor: PostAcceptor) {
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

  @Binding var title: String
  @ObservedObject var model: LinkPostForm.ViewModel

  var body: some View {
    VStack {
      TextField("post.new.title", text: $title)
        .font(.title2)
      TextField("post.new.link-to", text: $model.linkTo)
        .font(.title2)
    }
  }
}

// MARK: - ImageGifPostForm

private struct ImageGifPostForm: View {
  // MARK: Lifecycle

  init(for acceptor: PostAcceptor, title: Binding<String>, model: ViewModel) {
    self.acceptor = acceptor
    _title = title
    self.model = model
  }

  // MARK: Internal

  class ViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
      let validityToken = $selectedItems
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          self.isValid = !self.selectedItems.isEmpty
        }
      cancelBag.append(validityToken)
    }

    // MARK: Internal

    @Published var isValid: Bool = false
    @Published var posting: Bool = false
    @Published var presentImageSelector: Bool = false
    @Published var selectedItems: [URL] = []
    @Published var postResult: Result<NewPostResponse, AFError>? = nil
    @Published var galleryModel = GalleryCarousel.ViewModel()

    func submit(titled title: String, to acceptor: PostAcceptor) {
      if selectedItems.count > 1 {
        submitGalleryPost(titled: title, to: acceptor)
      } else {
        submitImagePost(titled: title, to: acceptor)
      }
    }

    // MARK: Private

    private var cancelBag: [AnyCancellable] = []

    private func submitImagePost(titled title: String, to acceptor: PostAcceptor) {
      let illithid: Illithid = .shared
      guard let url = selectedItems.first else { return }

      posting = true
      let uploadToken = illithid
        .uploadMedia(fileUrl: url)
        .flatMap { lease, _ in
          Publishers.Zip(illithid.receiveUploadResponse(lease: lease),
                         illithid.submit(kind: .image, subredditDisplayName: acceptor.uploadTarget,
                                         title: title, linkTo: lease.lease.retrievalUrl))
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
          illithid.logger.debugMessage("Successfully submitted image post: \(postResponse.json.data?.url?.absoluteString ?? "NO ASSOCIATED URL")")
        }
      cancelBag.append(uploadToken)
    }

    private func submitGalleryPost(titled title: String, to acceptor: PostAcceptor) {
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
          illithid.logger.debugMessage("Successfully submitted gallery post: \(postResponse.json.data?.url?.absoluteString ?? "NO ASSOCIATED URL")")
        })
      cancelBag.append(uploadToken)
    }
  }

  let acceptor: PostAcceptor
  @Binding var title: String
  @ObservedObject var model: Self.ViewModel

  var body: some View {
    VStack {
      TextField("post.new.title", text: $title)
        .font(.title2)
      Spacer()
      if acceptor.permitsGalleryPosts, !model.selectedItems.isEmpty {
        GalleryCarousel(model: model.galleryModel, urls: $model.selectedItems)
      } else if acceptor.permitsImagePosts, let imageUrl = model.selectedItems.first {
        AnimatedImage(url: imageUrl, isAnimating: .constant(true))
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: model.galleryModel.calculateImageWidth(for: imageUrl, height: 480), height: 480)
          .onHover { isHovered in
            withAnimation {
              self.isHovered = isHovered
            }
          }
          .deleteButton {
            model.selectedItems.removeAll()
          }
      } else {
        Button(action: { model.presentImageSelector = true }, label: {
          Text("choose.image")
        })
          .keyboardShortcut("o")
      }
      Spacer()
    }
    .fileImporter(isPresented: $model.presentImageSelector, allowedContentTypes: allowedContentTypes, allowsMultipleSelection: allowsMultipleItems) { result in
      switch result {
      case let .success(urls):
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
  }

  // MARK: Private

  @State private var isHovered: Bool = false
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

    func isGif(imagePath: URL) -> Bool {
      guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, imagePath.pathExtension as CFString, nil)?.takeRetainedValue(),
            let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else { return false }
      return mimeType as String == "image/gif"
    }

    func calculateImageWidth(for url: URL, height: CGFloat) -> CGFloat {
      let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
      guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions),
            let imageDetails = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any],
            let cfWidth = imageDetails[kCGImagePropertyPixelWidth as String] as! CFNumber?,
            let cfHeight = imageDetails[kCGImagePropertyPixelHeight as String] as! CFNumber?
      else { return 240 }
      var pixelWidth: CGFloat = 0, pixelHeight: CGFloat = 0
      CFNumberGetValue(cfWidth, .cgFloatType, &pixelWidth)
      CFNumberGetValue(cfHeight, .cgFloatType, &pixelHeight)

      return (pixelWidth * height) / pixelHeight
    }
  }

  @ObservedObject var model: Self.ViewModel
  @Binding var imageUrls: [URL]

  var body: some View {
    VStack {
      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(imageUrls, id: \.absoluteString) { url in
            UploadImagePreview(imageUrl: url, onRemoval: {
              withAnimation {
                if selected == url { selected = nil }
                imageUrls.removeAll(where: { $0 == url })
                model.removeItem(withUrl: url)
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
        HStack(spacing: 0) {
          Group {
            // The split here is to fix a bug when switching from a GIF to an image
            // Without it, the image resizes, but the first frame of the GIF is displayed
            if model.isGif(imagePath: selectedImage) {
              AnimatedImage(url: selectedImage, isAnimating: .constant(true))
                .resizable()
            } else {
              WebImage(url: selectedImage)
                .resizable()
            }
          }
          .aspectRatio(contentMode: .fill)
          .frame(width: model.calculateImageWidth(for: selectedImage, height: imageHeight), height: imageHeight)

          Divider()
            .padding(.horizontal)

          VStack {
            TextField("gallery.item.caption", text: model.titleBinding(for: selectedImage))
            TextField("gallery.item.link", text: model.outboundBinding(for: selectedImage))
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
  private let imageHeight: CGFloat = 480
}

// MARK: - UploadImagePreview

private struct UploadImagePreview: View {
  // MARK: Lifecycle

  init(imageUrl: URL, onRemoval: @escaping () -> Void, onUpload: @escaping (AssetUploadLease) -> Void) {
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

    func calculateImageWidth(for url: URL, height: CGFloat) -> CGFloat {
      let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
      guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions),
            let imageDetails = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any],
            let cfWidth = imageDetails[kCGImagePropertyPixelWidth as String] as! CFNumber?,
            let cfHeight = imageDetails[kCGImagePropertyPixelHeight as String] as! CFNumber?
      else { return 240 }
      var pixelWidth: CGFloat = 0, pixelHeight: CGFloat = 0
      CFNumberGetValue(cfWidth, .cgFloatType, &pixelWidth)
      CFNumberGetValue(cfHeight, .cgFloatType, &pixelHeight)

      return (pixelWidth * height) / pixelHeight
    }

    // MARK: Private

    private var uploadToken: AnyCancellable?
  }

  let imageUrl: URL
  let onRemoval: () -> Void

  var body: some View {
    GroupBox {
      AnimatedImage(url: imageUrl, isAnimating: .constant(false))
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: model.calculateImageWidth(for: imageUrl, height: imageHeight), height: imageHeight)
        .onHover { hovering in
          isHovering = hovering
        }
        .onAppear {
          model.upload(image: imageUrl)
        }
        .loadingScreen(isLoading: model.uploadResult == nil, dimBackground: true)
        .deleteButton {
          onRemoval()
        }
        .animation(.default)
    }
  }

  // MARK: Private

  @State private var isHovering: Bool = false
  @StateObject private var model: Self.ViewModel
  private let imageHeight: CGFloat = 240
}

// MARK: - VideoPostForm

private struct VideoPostForm: View {
  // MARK: Internal

  class ViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
      let validityToken = $selectedItem
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          self.isValid = self.selectedItem != nil
        }
      cancelBag.append(validityToken)
    }

    // MARK: Internal

    @Published var isValid: Bool = false
    @Published var posting: Bool = false
    @Published var presentVideoSelector: Bool = false
    @Published var selectedItem: URL? = nil
    @Published var postResult: Result<NewPostResponse, AFError>? = nil
    @Published var postAsGif: Bool = false

    func submit(titled title: String, to acceptor: PostAcceptor) {
      let illithid: Illithid = .shared
      guard let url = selectedItem else { return }

      posting = true
      let uploadToken = Publishers.Zip(illithid.uploadMedia(fileUrl: url), illithid.uploadMedia(image: getVideoThumbnail(from: url)!))
        .flatMap { [postAsGif] (videoUpload: (lease: AssetUploadLease, uploadResponse: Data), posterUpload: (lease: AssetUploadLease, uploadResponse: Data)) -> Publishers.Zip<AnyPublisher<MediaUploadResponse?, AFError>, AnyPublisher<NewPostResponse, AFError>> in
          let videoMetadata = videoUpload.lease
          let posterMetadata = posterUpload.lease
          return Publishers.Zip(illithid.receiveUploadResponse(lease: videoMetadata),
                                illithid.submit(kind: postAsGif ? .videogif : .video,
                                                subredditDisplayName: acceptor.uploadTarget,
                                                title: title,
                                                linkTo: videoMetadata.lease.retrievalUrl,
                                                videoPosterUrl: posterMetadata.lease.retrievalUrl))
        }
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { [weak self] completion in
          switch completion {
          case .finished:
            break
          case let .failure(error):
            self?.postResult = .failure(error)
            illithid.logger.errorMessage("Failed to submit video post: \(error)")
          }
          self?.posting = false
        }) { [weak self] _, postResponse in
          self?.postResult = .success(postResponse)
          illithid.logger.debugMessage("Successfully submitted video post: \(postResponse.json.data?.url?.absoluteString ?? "NO ASSOCIATED URL")")
        }
      cancelBag.append(uploadToken)
    }

    func getVideoThumbnail(from path: URL) -> CGImage? {
      let asset = AVURLAsset(url: path, options: nil)
      let imgGenerator = AVAssetImageGenerator(asset: asset)
      imgGenerator.appliesPreferredTrackTransform = true
      return try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
    }

    func getVideoDimensions() -> CGSize? {
      guard let url = selectedItem else { return nil }
      guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
      return track.naturalSize.applying(track.preferredTransform)
    }

    // MARK: Private

    private var cancelBag: [AnyCancellable] = []
  }

  @Binding var title: String
  @ObservedObject var model: Self.ViewModel

  var body: some View {
    VStack {
      TextField("post.new.title", text: $title)
        .font(.title2)
      Spacer()
      if let videoUrl = model.selectedItem {
        Group {
          if let size = model.getVideoDimensions() {
            VideoPlayer(url: videoUrl, fullSize: size)
          } else {
            VideoPlayer(url: videoUrl)
          }
        }
        .onHover { isHovered in
          withAnimation {
            self.isHovered = isHovered
          }
        }
        .deleteButton {
          model.selectedItem = nil
        }
      } else {
        Button(action: { model.presentVideoSelector = true }, label: {
          Text("choose.video")
        })
          .keyboardShortcut("o")
      }
      Spacer()
    }
    .fileImporter(isPresented: $model.presentVideoSelector, allowedContentTypes: [.mpeg4Movie, .quickTimeMovie]) { result in
      switch result {
      case let .success(url):
        model.selectedItem = url
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to select video: \(error)")
      }
    }
  }

  // MARK: Private

  @State private var isHovered: Bool = false
}
