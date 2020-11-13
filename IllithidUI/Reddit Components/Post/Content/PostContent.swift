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

import Alamofire
import Illithid
import SDWebImageSwiftUI
import Ulithari

// MARK: - PostContent

struct PostContent: View {
  let post: Post

  var body: some View {
    switch post.previewGuess {
    case .removed:
      RemovedPostView(removalCategory: post.removedByCategory!)
    case .imgur:
      ImgurView(link: post.contentUrl)
        .conditionalModifier(post.over18, NsfwBlurModifier())
        .mediaStamp("imgur")
    case .gfycat:
      GfycatView(id: String(post.contentUrl.path.dropFirst().split(separator: "-").first!))
        .conditionalModifier(post.over18, NsfwBlurModifier())
    case .redgifs:
      RedGifView(id: String(post.contentUrl.path.split(separator: "/").last!))
        .conditionalModifier(post.over18, NsfwBlurModifier())
    case .gallery:
      GalleryPost(metaData: post.mediaMetadata!, galleryData: post.galleryData!)
    case .text:
      TextPostPreview(post: post)
    case .gif:
      GifPostPreview(post: post)
        .conditionalModifier(post.over18, NsfwBlurModifier())
    case .video:
      VideoPostPreview(post: post)
        .conditionalModifier(post.over18, NsfwBlurModifier())
    case .image:
      ImagePostPreview(url: post.imagePreviews.last!.url)
        .conditionalModifier(post.over18, NsfwBlurModifier())
    case .reddit:
      RedditLinkView(link: post.contentUrl)
    case .link:
      LinkPreview(link: post.contentUrl, isNsfw: post.over18)
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
    case gallery

    /// Removed by user, admin, or moderator
    case removed

    // Site specific previews
    case imgur
    case gfycat
    case redgifs
    case reddit
  }

  /// Illithid's guess at the best type of preview to use for this post
  var previewGuess: PostPreviewType {
    if removedByCategory != nil {
      return .removed
    } else if domain.contains("imgur.com") {
      return .imgur
    } else if domain.contains("gfycat.com") {
      return .gfycat
    } else if domain.contains("redgifs.com") {
      return .redgifs
    } else if isGallery ?? false {
      return .gallery
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

// MARK: - RemovedPostView

struct RemovedPostView: View {
  // MARK: Internal

  let removalCategory: Post.RemovedByCategory

  var body: some View {
    GroupBox {
      Text(message)
    }
  }

  // MARK: Private

  private var message: String {
    switch removalCategory {
    case .moderator:
      return "This post has been removed by a moderator"
    }
  }
}

// MARK: - GalleryPost

struct GalleryPost: View {
  // MARK: Internal

  let metaData: [String: MediaMetadata]
  let galleryData: GalleryData

  var body: some View {
    PagedView(data: galleryData.items) { item in
      if let metadata = metaData[item.mediaId] {
        Group {
          switch metadata.type {
          case .image:
            ImagePostPreview(url: metadata.source.url!)
          case .animatedImage:
            AnimatedImage(url: metadata.source.mp4!)
          }
        }
        .overlay(
          captionView(item: item),
          alignment: .bottomLeading
        )
        // Prevent row from collapsing by enforcing the frame size
        .frame(width: min(CGFloat(metadata.source.width), ImagePostPreview.thumbnailFrame.width),
               height: min(CGFloat(metadata.source.height), ImagePostPreview.thumbnailFrame.height))
      }
    }
  }

  // MARK: Private

  private struct CaptionRectangle<Content: View>: View {
    // MARK: Lifecycle

    init(opacity: Double = 0.8, height: CGFloat = 30, @ViewBuilder label: @escaping () -> Content) {
      self.opacity = opacity
      self.height = height
      self.label = label
    }

    // MARK: Internal

    let opacity: Double
    let height: CGFloat
    let label: () -> Content

    var body: some View {
      Rectangle()
        .foregroundColor(.black)
        .opacity(opacity)
        .overlay(label())
        .frame(height: height)
    }
  }

  @ViewBuilder
  private func captionView(item: GalleryDataItem) -> some View {
    if let caption = item.caption {
      CaptionRectangle {
        HStack {
          if let url = item.outboundUrl {
            Link(caption, destination: url)
          } else {
            Text(caption)
          }
          Spacer()
        }
        .padding(.horizontal, 10)
      }
    } else if let url = item.outboundUrl {
      CaptionRectangle {
        HStack {
          Link(url.host ?? url.absoluteString, destination: url)
          Spacer()
        }
        .padding(.horizontal, 10)
      }
    } else {
      EmptyView()
    }
  }
}

// MARK: - VideoPostPreview

private struct VideoPostPreview: View {
  // MARK: Lifecycle

  init(post: Post) {
    self.post = post
    preview = post.bestVideoPreview!
  }

  // MARK: Internal

  let post: Post

  var body: some View {
    if let url = url {
      VideoPlayer(url: url, fullSize: .init(width: preview.width, height: preview.height))
        .mediaStamp("reddit")
    } else {
      Rectangle()
        .opacity(0.0)
        .onAppear {
          url = preview.url
        }
    }
  }

  // MARK: Private

  private let preview: Preview.Source

  @State private var url: URL? = nil
}

// MARK: - GifPostPreview

struct GifPostPreview: View {
  @State private var isAnimating: Bool = true

  let post: Post

  // Prefer the MP4 preview if available, it is much more efficient than a GIF
  var body: some View {
    if let mp4Preview = post.mp4Previews.last {
      VideoPlayer(url: mp4Preview.url, fullSize: .init(width: mp4Preview.width, height: mp4Preview.height))
        .mediaStamp("gif")
    } else {
      AnimatedImage(url: post.gifPreviews.last!.url, isAnimating: $isAnimating)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .mediaStamp("gif")
    }
  }
}

// MARK: - TextPostPreview

struct TextPostPreview: View {
  let post: Post

  var body: some View {
    if !post.selftext.isEmpty {
      GroupBox {
        VStack(alignment: .leading) {
          AttributedText(attributed: post.attributedSelfText)
            .padding(.horizontal)
        }
      }
      .frame(width: 512)
    }
  }
}

// MARK: - ImagePostPreview

struct ImagePostPreview: View {
  // MARK: Internal

  let url: URL

  var body: some View {
    WebImage(url: url, context: context)
      .dragAndZoom()
  }

  // MARK: Fileprivate

  fileprivate static let thumbnailFrame: CGSize = .init(width: 1536, height: 864)

  // MARK: Private

  private let context: [SDWebImageContextOption: Any] = [
    .imageThumbnailPixelSize: CGSize(width: thumbnailFrame.width,
                                     height: thumbnailFrame.height),
  ]
}
