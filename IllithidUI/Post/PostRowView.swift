//
// {file}
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import SwiftUI

import AlamofireImage
import Illithid

struct PostRowView: View {
  let reddit: Illithid = .shared
  let post: Post

  var body: some View {
    GroupBox {
      VStack {
        Text(self.post.title)
          .font(.title)
          .multilineTextAlignment(.center)
          .tooltip(post.title)
          .padding()

        PostPreview(post: post)

        PostMetadataBar(post: post)
      }
    }
  }
}

struct PostMetadataBar: View {
  @State var authorPopover = false
  let post: Post

  var body: some View {
    HStack {
      Button(post.author) {
        self.authorPopover.toggle()
      }
      .popover(isPresented: $authorPopover) {
        AccountView(accountData: .init(name: self.post.author))
      }
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
