//
// PostContent.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/9/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI
import Ulithari

struct PostContent: View {
  let post: Post

  var body: AnyView {
    switch post.previewGuess {
    case .imgur:
      return ImgurView(link: post.contentUrl)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .mediaStamp("imgur")
        .eraseToAnyView()
    case .gfycat:
      return GfycatView(gfyId: String(post.contentUrl.path.dropFirst().split(separator: "-").first!))
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .mediaStamp("gfycat")
        .eraseToAnyView()
    case .redgifs:
      return RedGifView(id: String(post.contentUrl.path.split(separator: "/").last!))
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .mediaStamp("redgifs")
        .eraseToAnyView()
    case .text:
      return TextPostPreview(text: post.selftext)
        .eraseToAnyView()
    case .gif:
      return GifPostPreview(post: post)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .eraseToAnyView()
    case .video:
      return VideoPostPreview(post: post)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .eraseToAnyView()
    case .image:
      return ImagePostPreview(url: post.imagePreviews.last!.url)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .eraseToAnyView()
    case .reddit:
      return RedditLinkView(link: post.contentUrl)
        .eraseToAnyView()
    case .link:
      return LinkPreview(link: post.contentUrl, isNsfw: post.over18)
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
    if let url = url {
      return VideoPlayer(url: url, fullSize: .init(width: preview.width, height: preview.height))
        .mediaStamp("reddit")
        .eraseToAnyView()
    } else {
      return Rectangle()
        .opacity(0.0)
        .onAppear {
          url = preview.url
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
    case redgifs
    case reddit
  }

  /// Illithid's guess at the best type of preview to use for this post
  var previewGuess: PostPreviewType {
    if domain.contains("imgur.com") {
      return .imgur
    } else if domain.contains("gfycat.com") {
      return .gfycat
    } else if domain.contains("redgifs.com") {
      return .redgifs
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
  @StateObject private var gfyData: GfycatData

  init(gfyId id: String) {
    _gfyData = .init(wrappedValue: GfycatData(gfyId: id))
  }

  var body: some View {
    VStack {
      if let url = gfyData.item?.mp4URL {
        VideoPlayer(url: url, fullSize: .init(width: gfyData.item!.width, height: gfyData.item!.height))
      } else {
        EmptyView()
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

// MARK: RedGifs

struct RedGifView: View {
  @StateObject private var data: RedGifData

  init(id: String) {
    _data = .init(wrappedValue: RedGifData(id: id))
  }

  var body: some View {
    VStack {
      if let url = data.item?.mp4URL {
        VideoPlayer(url: url, fullSize: .init(width: data.item!.width, height: data.item!.height))
      } else {
        EmptyView()
      }
    }
  }
}

class RedGifData: ObservableObject {
  @Published var item: GfyItem? = nil
  let id: String
  let ulithari: Ulithari = .shared

  init(id: String) {
    self.id = id
    ulithari.fetchRedGif(id: id) { result in
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
          if imgurData.images.count > 1 {
            MediaStamp(mediaType: "\(viewIndex + 1) / \(imgurData.images.count)")
          }
          renderImageView(image: imgurData.images[viewIndex])
            .animation(.default)
            .onTapGesture {
              viewIndex = (viewIndex + 1) % imgurData.images.count
            }
        }
      }
    }
    .onAppear {
      guard imgurData.images.isEmpty else { return }
      imgurData.loadContent()
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

  private let context: [SDWebImageContextOption: Any] = [
    .imageThumbnailPixelSize: CGSize(width: 1536, height: 864),
  ]

  var body: some View {
    WebImage(url: url, context: context)
      .dragAndZoom()
  }
}
