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
        RemoteImage(subreddit.headerImageURL!, imageDownloader: self.reddit.imageDownloader)
          .padding()
      } else {
        // TODO: Replace with proper placeholder image
        Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
          .padding()
      }

      VStack {
        Text(verbatim: subreddit.displayName)
          .font(.title).padding()

        //                Text(verbatim: subreddit.publicDescription)
        //                  .lineLimit(nil)
      }

      Spacer()
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
