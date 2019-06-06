//
//  SubredditsView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/5/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct SubredditsView: View {
  let reddit: RedditClientBroker
  @EnvironmentObject var subredditData: SubredditData

  var body: some View {
    List {
      VStack(alignment: .center) {
        HStack(alignment: .center) {
          Text("Subreddits")
            .font(.largeTitle)
            .padding()
        }
      }
      ForEach(subredditData.subreddits) { subreddit in
        VStack(alignment: .center) {
          Text(verbatim: subreddit.displayName)
            .font(.title)
            .padding()
          Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
            .padding()
        }
      }
    }
    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
    .onAppear {
      self.loadSubreddits()
    }
  }

  func loadSubreddits() {
    reddit.subreddits { listing in
      listing.metadata.children.forEach { self.subredditData.subreddits.append($0.object) }
    }
  }
}

#if DEBUG
struct SubredditsView_Previews: PreviewProvider {
  static var previews: some View {
    SubredditsView(reddit: .init())
      .previewDevice("MacBookPro15,1")
      .environmentObject(SubredditData())
  }
}
#endif
