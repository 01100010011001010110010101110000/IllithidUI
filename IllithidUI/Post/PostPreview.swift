//
// PostPreview.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct PostPreview: View {
  @State private var isAnimating: Bool = false
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
          .onHover { inFrame in
            self.isAnimating = inFrame
          }
          .onDisappear { self.isAnimating = false }
          .frame(width: CGFloat(integerLiteral: post.gifPreviews.last!.width),
                 height: CGFloat(integerLiteral: post.gifPreviews.last!.height))
      } else if post.previewGuess == .video {
        VideoPostPreview(post: self.post)
      } else if post.previewGuess == .image {
        if !post.imagePreviews.isEmpty {
          WebImage(url: post.imagePreviews.middle!.url)
            .frame(width: CGFloat(integerLiteral: post.imagePreviews.middle!.width),
                   height: CGFloat(integerLiteral: post.imagePreviews.middle!.height))
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

struct PostPreview_Previews: PreviewProvider {
  static var previews: some View {
    EmptyView()
  }
}
