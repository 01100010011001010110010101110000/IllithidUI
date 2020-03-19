//
// PostPreview.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid
import SDWebImage
import SDWebImageSwiftUI
import Ulithari

struct PostContent: View {
  let post: Post

  var body: AnyView {
    if post.previewGuess == .imgur {
      return ImgurView(imageId: String(post.contentUrl.path.dropFirst().split(separator: ".").first!))
        .draggable()
        .zoomable()
        .overlay(MediaStamp(mediaType: "imgur")
          .padding([.bottom, .trailing], 4),
                 alignment: .bottomTrailing)
      .eraseToAnyView()
    } else if post.previewGuess == .gfycat {
      return GfycatView(gfyId: String(post.contentUrl.path.dropFirst().split(separator: "-").first!))
        .overlay(MediaStamp(mediaType: "gfycat")
          .padding([.bottom, .trailing], 4),
                 alignment: .bottomTrailing)
      .eraseToAnyView()
    } else if post.previewGuess == .text {
      return TextPostPreview(text: post.selftext)
        .eraseToAnyView()
    } else if post.previewGuess == .gif {
      return GifPostPreview(url: post.gifPreviews.last!.url)
        .eraseToAnyView()
    } else if post.previewGuess == .video {
      return VideoPostPreview(post: self.post)
        .eraseToAnyView()
    } else if post.previewGuess == .image {
      return ImagePostPreview(images: post.imagePreviews)
        .eraseToAnyView()
    } else if post.previewGuess == .reddit {
      return RedditLinkView(link: post.contentUrl)
        .eraseToAnyView()
    } else if post.previewGuess == .link {
      return LinkPreview(link: post.contentUrl)
        .eraseToAnyView()
    } else {
      return Text("No available preview")
        .eraseToAnyView()
    }
  }
}

struct MediaStamp: View {
  let mediaType: String

  var body: some View {
    Text(mediaType)
      .font(.caption)
      .foregroundColor(.black)
      .padding(4)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .foregroundColor(.white)
      )
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
    VStack {
      if self.url != nil {
        VideoPlayer(url: self.url!, fullSize: .init(width: preview.width, height: preview.height))
      } else {
        Rectangle()
          .opacity(0.0)
          .onAppear {
            self.url = self.preview.url
          }
      }
    }
    .overlay(MediaStamp(mediaType: "reddit")
      .padding([.bottom, .trailing], 4),
             alignment: .bottomTrailing)
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
    } else if isSelf || postHint == .`self` {
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

//    // Video previews
//    guard let postPreview = preview else { return nil }
//    if let redditPreview = postPreview.redditVideoPreview {
//      return Preview.Source(url: redditPreview.hlsUrl, width: redditPreview.width, height: redditPreview.height)
//    } else if let mp4Preview = postPreview.images.first?.variants?.mp4 {
//      return mp4Preview.resolutions.middle ?? mp4Preview.source
//    }

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
  @ObservedObject var imgurData: ImgurData

  init(imageId: String) {
    imgurData = .init(imageId: imageId)
  }

  var body: some View {
    imgurData.imgurImage.map { image in
      VStack {
        if image.data.animated {
          VideoPlayer(url: imgurData.imgurImage!.data.mp4!,
                      fullSize: .init(width: imgurData.imgurImage!.data.width,
                                      height: imgurData.imgurImage!.data.height))
        } else {
          WebImage(url: image.data.link)
            .resizable()
            .scaledToFit()
            .heightResizable()
            .draggable()
            .zoomable()
        }
      }
    }
  }
}

class ImgurData: ObservableObject {
  @Published var imgurImage: ImgurImage? = nil
  let ulithari: Ulithari = .shared

  init(imageId: String) {
    ulithari.fetchImgurImage(id: imageId) { result in
      switch result {
      case let .success(imgurImage):
        self.imgurImage = imgurImage
      case let .failure(error):
        Illithid.shared.logger.errorMessage("Failed to fetch \(imageId) data: \(error)")
      }
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

  let url: URL

  var body: some View {
    AnimatedImage(url: url, isAnimating: $isAnimating)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .overlay(MediaStamp(mediaType: "gif")
        .padding([.bottom, .trailing], 4),
               alignment: .bottomTrailing)
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
  let images: [Preview.Source]

  var body: some View {
    WebImage(url: images.last!.url)
      .resizable()
      .scaledToFit()
      .heightResizable()
      .draggable()
      .zoomable()
  }
}
