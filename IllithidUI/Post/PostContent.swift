//
// PostPreview.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI
import Ulithari

struct PostContent: View {
  @State private var isAnimating: Bool = true
  let post: Post

  var body: some View {
    VStack {
      if post.previewGuess == .imgur {
        ImgurView(imageId: String(post.contentUrl.path.dropFirst().split(separator: ".").first!))
          .overlay(MediaStamp(mediaType: "imgur")
            .padding([.bottom, .trailing], 4),
                   alignment: .bottomTrailing)
      } else if post.previewGuess == .gfycat {
        GfycatView(gfyId: String(post.contentUrl.path.dropFirst()))
          .overlay(MediaStamp(mediaType: "gfycat")
            .padding([.bottom, .trailing], 4),
                   alignment: .bottomTrailing)
      } else if post.previewGuess == .text {
        ScrollView {
          Text(post.selftext)
            .padding()
        }
      } else if post.previewGuess == .gif {
        AnimatedImage(url: post.gifPreviews.last!.url, isAnimating: $isAnimating)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .overlay(MediaStamp(mediaType: "gfycat")
            .padding([.bottom, .trailing], 4),
                   alignment: .bottomTrailing)
      } else if post.previewGuess == .video {
        VideoPostPreview(post: self.post)
      } else if post.previewGuess == .image {
        if !post.imagePreviews.isEmpty {
          WebImage(url: post.imagePreviews.middle!.url)
            .resizable()
            .aspectRatio(contentMode: .fit)
        } else {
          Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
            .scaledToFit()
            .frame(width: 96, height: 96)
        }
      } else if post.previewGuess == .link {
        LinkPreview(link: post.contentUrl)
          .fixedSize(horizontal: true, vertical: false)
      }
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
        Player(url: self.url!)
      } else {
        Rectangle()
          .opacity(0.0)
          .onAppear {
            self.url = self.preview.url
          }
      }
    }
    .frame(width: CGFloat(preview.width), height: CGFloat(preview.height))
    .overlay(MediaStamp(mediaType: "video")
      .padding([.bottom, .trailing], 4),
             alignment: .bottomTrailing)
  }
}

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
  }

  /// Illithid's guess at the best type of preview to use for this post
  var previewGuess: PostPreviewType {
    if domain.contains("imgur.com") {
      return .imgur
    } else if domain.contains("gfycat.com") {
      return .gfycat
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

struct GfycatView: View {
  @ObservedObject var gfyData: GfycatData

  init(gfyId id: String) {
    gfyData = .init(gfyId: id)
  }

  var body: some View {
    VStack {
      if gfyData.item == nil {
        EmptyView()
      } else if gfyData.item!.hasAudio {
        Player(url: gfyData.item!.mp4URL)
          .frame(width: CGFloat(gfyData.item!.width), height: CGFloat(gfyData.item!.height))
      } else {
        Player(url: gfyData.item!.mp4URL)
          .frame(width: CGFloat(gfyData.item!.width), height: CGFloat(gfyData.item!.height))
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
    ulithari.fetchGfycat(id: id, queue: .global(qos: .userInteractive)) { result in
      switch result {
      case let .success(item):
        DispatchQueue.main.async {
          self.item = item
        }
      case let .failure(error):
        print("Failed to fetch gfyitem: \(error)")
      }
    }
  }
}

struct ImgurView: View {
  @ObservedObject var imgurData: ImgurData

  init(imageId: String) {
    imgurData = .init(imageId: imageId)
  }

  var body: some View {
    VStack {
      if imgurData.imgurImage == nil {
        EmptyView()
      } else if imgurData.imgurImage!.data.animated {
        if imgurData.imgurImage!.data.hasSound {
          Player(url: imgurData.imgurImage!.data.hls!)
            .frame(width: CGFloat(integerLiteral: imgurData.imgurImage!.data.width),
                   height: CGFloat(integerLiteral: imgurData.imgurImage!.data.height))
        } else {
          Player(url: imgurData.imgurImage!.data.hls!)
            .frame(width: CGFloat(integerLiteral: imgurData.imgurImage!.data.width),
                 height: CGFloat(integerLiteral: imgurData.imgurImage!.data.height))
        }
      } else {
        WebImage(url: imgurData.imgurImage!.data.link)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
    }
  }
}

class ImgurData: ObservableObject {
  @Published var imgurImage: ImgurImage? = nil
  let ulithari: Ulithari = .shared

  init(imageId: String) {
    ulithari.fetchImgurImage(id: imageId, queue: .global(qos: .userInteractive)) { result in
      switch result {
      case let .success(imgurImage):
        DispatchQueue.main.async {
          self.imgurImage = imgurImage
        }
      case let .failure(error):
        print("Failed to fetch \(imageId) data: \(error)")
      }
    }
  }
}

struct PostPreview_Previews: PreviewProvider {
  static var previews: some View {
    EmptyView()
  }
}
