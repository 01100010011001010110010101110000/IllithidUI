//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import SwiftUI

import Illithid

struct PostPreview: View {
  let post: Post

  @State var player: Player? = nil

  var body: some View {
    VStack {
      if post.previewGuess == .text {
        ScrollView {
          Text(post.selftext)
            .padding()
        }
      } else if post.previewGuess == .video {
        if self.player != nil {
          ZStack(alignment: .bottomTrailing) {
            self.player!
              .frame(width: CGFloat(post.preview!.redditVideoPreview!.width),
                     height: CGFloat(post.preview!.redditVideoPreview!.height))
            Text("gif")
              .foregroundColor(.black)
              .padding(2)
              .background(
                RoundedRectangle(cornerRadius: 4)
                  .foregroundColor(.white)
              )
          }
        } else {
          Rectangle()
            .frame(width: CGFloat(post.preview!.redditVideoPreview!.width),
                   height: CGFloat(post.preview!.redditVideoPreview!.height))
            .onAppear {
              self.player = Player(url: self.post.preview!.redditVideoPreview!.hlsUrl)
          }
        }
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
    } else if preview?.redditVideoPreview?.scrubberMediaUrl != nil ||
        preview?.images.first?.variants?.mp4 != nil {
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
}
