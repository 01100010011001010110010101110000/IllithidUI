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
      if post.postHint == .`self` || post.isSelf {
        if !post.selftext.isEmpty {
          ScrollView {
            Text(post.selftext)
              .padding()
          }
        }
      } else if post.preview?.redditVideoPreview?.scrubberMediaUrl != nil {
        // This also covers post.postHint == .hostedVideo or .richVideo
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
          EmptyView()
            .frame(width: CGFloat(post.preview!.redditVideoPreview!.width),
                   height: CGFloat(post.preview!.redditVideoPreview!.height))
            .onAppear {
              self.player = Player(url: self.post.preview!.redditVideoPreview!.hlsUrl)
          }
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
          ScrollView {
            Text(post.selftext)
              .padding()
          }
        } else {
          LinkPreview(link: post.contentUrl)
            .fixedSize(horizontal: true, vertical: false)
        }
      }
    }
  }
}
