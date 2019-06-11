//
//  PostRowView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct PostRowView : View {
  let post: Post
  let reddit: RedditClientBroker

    var body: some View {
      GroupBox {
        VStack(alignment: .midStatsAndPreview) {
          Text(post.title)
            .font(.title)


          if post.thumbnail != nil {
            RemoteImage(post.thumbnail!, imageDownloader: self.reddit.imageDownloader)
              .alignmentGuide(.midStatsAndPreview) { d in d[HorizontalAlignment.center]}
          } else {
            // TODO: Replace with proper placeholder image
            Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
              .alignmentGuide(.midStatsAndPreview) { d in d[HorizontalAlignment.center]}
          }

          HStack {
            Text(post.author)
              .padding([.vertical, .leading])
            Spacer()
            HStack {
              Text("\(post.ups.postAbbreviation())")
                .foregroundColor(.orange)
              Text("\(post.downs.postAbbreviation())")
                .foregroundColor(.purple)
              Text("\(post.num_comments.postAbbreviation())")
                .foregroundColor(.blue)
              }.alignmentGuide(.midStatsAndPreview) { d in d[HorizontalAlignment.center]}
            Spacer()
            Text(post.subreddit_name_prefixed)
              .padding([.trailing, .vertical])
          }
        }
      }
    }
}

//#if DEBUG
//struct PostRowView_Previews : PreviewProvider {
//    static var previews: some View {
//        PostRowView()
//    }
//}
//#endif
