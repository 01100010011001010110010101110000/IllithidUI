//
//  PostRowView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import AlamofireImage
import Illithid

struct PostRowView: View {
  let reddit: RedditClientBroker = .shared
  var post: Post
  let previews: [ImagePreview.Image]

  init(post: Post) {
    self.post = post
    self.previews = post.previews
  }

  var body: some View {
    GroupBox {
      VStack(alignment: .midStatsAndPreview) {
        GeometryReader { geometry in
          Text(self.post.title)
            .font(.title)
            .multilineTextAlignment(.center)
            .frame(maxWidth: geometry.size.width)
        }

        if !previews.isEmpty {
          RemoteImage(previews.middle.url)
            .frame(width: CGFloat(integerLiteral: previews.middle.width),
                   height: CGFloat(integerLiteral: previews.middle.height))
            .alignmentGuide(.midStatsAndPreview) { d in d[HorizontalAlignment.center] }
            .cornerRadius(10)
        } else {
          // TODO: Replace with proper placeholder image
          Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
            .alignmentGuide(.midStatsAndPreview) { d in d[HorizontalAlignment.center] }
        }

        HStack {
          Text(post.author)
          Spacer()
          HStack {
            Text("\(post.ups.postAbbreviation())")
              .foregroundColor(.orange)
            Text("\(post.downs.postAbbreviation())")
              .foregroundColor(.purple)
            Text("\(post.numComments.postAbbreviation())")
              .foregroundColor(.blue)
          }.alignmentGuide(.midStatsAndPreview) { d in d[HorizontalAlignment.center] }
          Spacer()
          Text(post.subredditNamePrefixed)
        }
        .padding(10)
        .font(.caption)
      }
    }
  }
}

#if DEBUG
struct PostRowView_Previews: PreviewProvider {
  static let reddit: RedditClientBroker = .shared

  static var previews: some View {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    let singlePostURL = Bundle.main.url(forResource: "single_post", withExtension: "json")!
    let data = try! Data(contentsOf: singlePostURL)
    let post = try! decoder.decode(Post.self, from: data)
    return PostRowView(post: post).environmentObject(self.reddit)
  }
}
#endif
