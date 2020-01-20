//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import SwiftUI

import Illithid

struct PostPreview: View {
  let post: Post

  var body: some View {
    VStack {
      if post.previewGuess == .text {
        ScrollView {
          Text(post.selftext)
            .padding()
        }
      } else if post.previewGuess == .video {
        VideoPostPreview(post: self.post)
      } else if post.previewGuess == .image {
        if !post.imagePreviews.isEmpty {
          RemoteImage(post.imagePreviews.middle!.url)
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

private struct VideoPostPreview: View {
  let post: Post
  private let preview: Preview.Source?

  @State var player: Player? = nil

  init(post: Post) {
    self.post = post
    preview = post.bestVideoPreview
  }

  var body: some View {
    VStack {
      if preview == nil {
        Text("No available video preview")
      } else if self.player != nil {
        ZStack(alignment: .bottomTrailing) {
          self.player!
            .frame(width: CGFloat(preview!.width), height: CGFloat(preview!.height))
          Text("gif")
            .foregroundColor(.black)
            .padding(4)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .foregroundColor(.white)
            )
        }
      } else {
        Rectangle()
          .frame(width: CGFloat(preview!.width),
                 height: CGFloat(preview!.height))
          .onAppear {
            self.player = Player(url: self.preview!.url)
          }
      }
    }
  }
}

extension Post {
  enum PostPreviewType: String {
    case image
    case link
    case text
    case video
  }

  /// Illithid's guess at the best type of preview to use for this post
  var previewGuess: PostPreviewType {
    if isSelf || postHint == .`self` {
      return .text
    } else if bestVideoPreview != nil {
      return .video
    } else if postHint == .link && domain != "imgur.com" {
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
    guard let postPreview = preview else { return nil }
    if let redditPreview = postPreview.redditVideoPreview {
      return Preview.Source(url: redditPreview.hlsUrl, width: redditPreview.width, height: redditPreview.height)
    } else if let mp4Preview = postPreview.images.first?.variants?.mp4 {
      return mp4Preview.resolutions.middle ?? mp4Preview.source
    }
    return nil
  }
}
