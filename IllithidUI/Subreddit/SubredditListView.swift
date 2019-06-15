//
//  SubredditsView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/5/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid
import Willow

struct SubredditsView: View {
  @State private var listingParams: ListingParams = .init()
  @EnvironmentObject var subredditData: SubredditData

  let reddit: RedditClientBroker

  var body: some View {
    NavigationView {
      List {
        ForEach(self.subredditData.subreddits) { subreddit in
          NavigationButton(destination: PostListView(postsData: PostData(), subreddit: subreddit, reddit: self.reddit)) {
            SubredditRowView(subreddit: subreddit, reddit: self.reddit)
          }
        }
      }
    }
    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
    .onAppear {
      self.loadSubreddits()
    }
  }

  func loadSubreddits() {
    reddit.subreddits(params: listingParams) { listing in
      if let anchor = listing.metadata.after { self.listingParams.after = anchor }
      listing.metadata.children.forEach { subreddit in
        self.subredditData.subreddits.append(subreddit.object)
      }
    }
  }
}

//#if DEBUG
//struct SubredditsView_Previews: PreviewProvider {
//  static var previews: some View {
//    SubredditsView(reddit: .init())
//      .previewDevice("MacBookPro15,1")
//      .environmentObject(SubredditData())
//  }
//}
//#endif
