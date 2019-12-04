//
//  PostPreview.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/18/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct PostPreview: View {
  let post: Post

  var body: some View {
    return VStack {
      if post.postHint == .`self` {
        Text(post.selftext)
      } else if post.postHint == .hostedVideo || post.postHint == .richVideo {
        if post.preview?.redditVideoPreview?.scrubberMediaUrl != nil {
          Player(url: post.preview!.redditVideoPreview!.hlsUrl)
            .frame(width: CGFloat(post.preview!.redditVideoPreview!.width),
                   height: CGFloat(post.preview!.redditVideoPreview!.height))
        }
      } else if post.postHint == .image {
        if !post.previews.isEmpty {
          RemoteImage(post.previews.middle!.url)
            .frame(width: CGFloat(integerLiteral: post.previews.middle!.width),
                   height: CGFloat(integerLiteral: post.previews.middle!.height))
        } else {
          Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
            .scaledToFit()
            .frame(width: 96, height: 96)
        }
      } else if post.postHint == .link {
        LinkPreview(link: post.contentUrl)
          .fixedSize(horizontal: true, vertical: false)
      } else {
        // There was no post hint or it did not match any prior case
        if !post.selftext.isEmpty {
          Text(post.selftext)
        } else {
          LinkPreview(link: post.contentUrl)
            .fixedSize(horizontal: true, vertical: false)
        }
      }
    }
  }
}
