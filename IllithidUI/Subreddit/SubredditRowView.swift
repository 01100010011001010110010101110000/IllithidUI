//
//  SubredditRowView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct SubredditRowView: View {
  let subreddit: Subreddit
  let reddit: RedditClientBroker

  var body: some View {
    HStack {
      if subreddit.headerImageURL != nil {
        RemoteImage(subreddit.headerImageURL!, imageDownloader: self.reddit.imageDownloader, resizable: true)
          .scaledToFit()
          .frame(width: 96, height: 96)
      } else {
        // TODO: Replace with proper placeholder image
        Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
          .scaledToFit()
          .frame(width: 96, height: 96)
      }
      Text(verbatim: subreddit.displayName)
        .font(.headline)
        .padding(.leading)
    }
  }
}

// #if DEBUG
// struct SubredditRowView_Previews : PreviewProvider {
//    static var previews: some View {
//        SubredditRowView()
//    }
// }
// #endif
