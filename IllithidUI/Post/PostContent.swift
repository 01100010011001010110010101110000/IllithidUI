//
// PostContent.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 5/3/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI
import Ulithari

struct PostContent: View {
  let post: Post

  var body: AnyView {
    if post.previewGuess == .imgur {
      return ImgurView(link: post.contentUrl)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .mediaStamp("imgur")
        .eraseToAnyView()
    } else if post.previewGuess == .gfycat {
      return GfycatView(gfyId: String(post.contentUrl.path.dropFirst().split(separator: "-").first!))
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .mediaStamp("gfycat")
        .eraseToAnyView()
    } else if post.previewGuess == .text {
      return TextPostPreview(text: post.selftext)
        .eraseToAnyView()
    } else if post.previewGuess == .gif {
      return GifPostPreview(post: post)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .eraseToAnyView()
    } else if post.previewGuess == .video {
      return VideoPostPreview(post: post)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .eraseToAnyView()
    } else if post.previewGuess == .image {
      return ImagePostPreview(url: post.imagePreviews.last!.url)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .eraseToAnyView()
    } else if post.previewGuess == .reddit {
      return RedditLinkView(link: post.contentUrl)
        .eraseToAnyView()
    } else if post.previewGuess == .link {
      return LinkPreview(link: post.contentUrl, isNsfw: post.over18)
        .eraseToAnyView()
    } else {
      return Text("No available preview")
        .eraseToAnyView()
    }
  }
}

private struct VideoPostPreview: View {
  let post: Post
  private let preview: Preview.Source

  @State private var url: URL? = nil

  init(post: Post) {
    self.post = post
    preview = post.bestVideoPreview!
  }

  var body: some View {
    if self.url != nil {
      return VideoPlayer(url: self.url!, fullSize: .init(width: preview.width, height: preview.height))
        .mediaStamp("reddit")
        .eraseToAnyView()
    } else {
      return Rectangle()
        .opacity(0.0)
        .onAppear {
          self.url = self.preview.url
        }
        .eraseToAnyView()
    }
  }
}

// MARK: Preview guessing

extension Post {
  enum PostPreviewType: String {
    case image
    case link
    case text
    case video
    case gif

    // Site specific previews
    case imgur
    case gfycat
    case reddit
  }

  /// Illithid's guess at the best type of preview to use for this post
  var previewGuess: PostPreviewType {
    if domain.contains("imgur.com") {
      return .imgur
    } else if domain.contains("gfycat.com") {
      return .gfycat
    } else if domain == "reddit.com" || domain == "old.reddit.com" {
      return .reddit
    } else if isSelf || postHint == .self {
      return .text
    } else if bestVideoPreview != nil {
      return .video
    } else if !gifPreviews.isEmpty {
      return .gif
    } else if postHint == .link {
      return .link
    } else if postHint == .image || !imagePreviews.isEmpty {
      return .image
    } else if !selftext.isEmpty {
      return .text
    } else {
      return .link
    }
  }

  var bestVideoPreview: Preview.Source? {
    // Reddit hosted videos
    if let redditVideo = secureMedia?.redditVideo {
      return Preview.Source(url: redditVideo.hlsUrl, width: redditVideo.width, height: redditVideo.height)
    } else if let redditVideo = media?.redditVideo {
      return Preview.Source(url: redditVideo.hlsUrl, width: redditVideo.width, height: redditVideo.height)
    }

    // Video previews
    if let redditPreview = preview?.redditVideoPreview {
      return Preview.Source(url: redditPreview.hlsUrl, width: redditPreview.width, height: redditPreview.height)
    } else if let mp4Preview = mp4Previews.last {
      return mp4Preview
    }

    return nil
  }
}

// MARK: Gfycat

struct GfycatView: View {
  @ObservedObject var gfyData: GfycatData

  init(gfyId id: String) {
    gfyData = .init(gfyId: id)
  }

  var body: some View {
    VStack {
      if gfyData.item == nil {
        EmptyView()
      } else {
        VideoPlayer(url: gfyData.item!.mp4URL,
                    fullSize: .init(width: gfyData.item!.width,
                                    height: gfyData.item!.height))
      }
    }
  }
}

class GfycatData: ObservableObject {
  @Published var item: GfyItem? = nil
  let id: String
  let ulithari: Ulithari = .shared

  init(gfyId id: String) {
    self.id = id
    ulithari.fetchGfycat(id: id) { result in
      switch result {
      case let .success(item):
        self.item = item
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch gfyitem \(id): \(error)")
      }
    }
  }
}

// MARK: Imgur

struct ImgurView: View {
  @State private var viewIndex: Int = 0
  @ObservedObject var imgurData: ImgurData

  init(link: URL) {
    imgurData = .init(link)
  }

  var body: some View {
    Group {
      if imgurData.images.isEmpty {
        Rectangle()
          .opacity(0)
      } else {
        ZStack(alignment: .topTrailing) {
          if self.imgurData.images.count > 1 {
            MediaStamp(mediaType: "\(self.viewIndex + 1) / \(self.imgurData.images.count)")
          }
          renderImageView(image: imgurData.images[viewIndex])
            .animation(.default)
            .onTapGesture {
              self.viewIndex = (self.viewIndex + 1) % self.imgurData.images.count
            }
        }
      }
    }
    .onAppear {
      guard self.imgurData.images.isEmpty else { return }
      self.imgurData.loadContent()
    }
  }

  private func renderImageView(image: ImgurImage) -> AnyView {
    if image.animated {
      return VideoPlayer(url: image.mp4!,
                         fullSize: .init(width: image.width,
                                         height: image.height))
        .eraseToAnyView()
    } else {
      return ImagePostPreview(url: image.link)
        .eraseToAnyView()
    }
  }
}

final class ImgurData: ObservableObject {
  @Published var images: [ImgurImage] = []

  let link: URL

  private let ulithari: Ulithari = .shared

  init(_ link: URL) {
    self.link = link
  }

  func loadContent() {
    switch ulithari.imgurLinkType(link) {
    case let .album(id):
      ulithari.fetchImgurAlbum(id: id) { result in
        switch result {
        case let .success(album):
          self.images.append(contentsOf: album.images)
        case let .failure(error):
          Illithid.shared.logger.errorMessage("Error fetching imgur album with id \(id): \(error)")
        }
      }
    case .gallery:
      // TODO: - implement gallery support
      return
    case let .image(id):
      ulithari.fetchImgurImage(id: id) { result in
        _ = result.map { self.images.append($0) }
      }
    case nil:
      // Invalid link
      return
    }
  }
}

struct PostPreview_Previews: PreviewProvider {
  static var previews: some View {
    EmptyView()
  }
}

struct GifPostPreview: View {
  @State private var isAnimating: Bool = true

  let post: Post

  // Prefer the MP4 preview if available, it is much more efficient than a GIF
  var body: some View {
    if let mp4Preview = post.mp4Previews.last {
      return VideoPlayer(url: mp4Preview.url, fullSize: .init(width: mp4Preview.width, height: mp4Preview.height))
        .mediaStamp("gif")
        .eraseToAnyView()
    } else {
      return AnimatedImage(url: post.gifPreviews.last!.url, isAnimating: $isAnimating)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .mediaStamp("gif")
        .eraseToAnyView()
    }
  }
}

struct TextPostPreview: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.body)
      .padding()
      .heightResizable()
  }
}

struct ImagePostPreview: View {
  let url: URL

  var body: some View {
    WebImage(url: url)
      .resizable()
      .scaledToFit()
      .heightResizable(maxHeight: 800)
      .dragAndZoom()
  }
}
