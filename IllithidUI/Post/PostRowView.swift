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
  let reddit: Illithid = .shared
  var post: Post
  let previews: [Preview.Source]

  init(post: Post) {
    self.post = post
    previews = post.previews
  }

  var body: some View {
    ScrollView {
      GroupBox {
        VStack {
          Text(self.post.title)
            .font(.title)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

          PostPreview(post: post)

          PostMetadataBar(post: post)
        }
      }
    }
  }
}

struct PostMetadataBar: View {
  let post: Post

  var body: some View {
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
      }
      Spacer()
      Text(post.subredditNamePrefixed)
    }
    .padding(10)
    .font(.caption)
  }
}

#if DEBUG
  struct PostRowView_Previews: PreviewProvider {
    static var previews: some View {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      decoder.dateDecodingStrategy = .secondsSince1970

      let singlePostURL = Bundle.main.url(forResource: "single_post", withExtension: "json")!
      let data = try! Data(contentsOf: singlePostURL)
      let post = try! decoder.decode(Post.self, from: data)

      return PostRowView(post: post).environmentObject(ImageDownloader())
    }
  }
#endif
