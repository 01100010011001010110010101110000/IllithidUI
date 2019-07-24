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
  @State private var listingParams: ListingParameters = .init()
  @EnvironmentObject var subredditData: SubredditData
  @State private var subreddit: Subreddit? = nil

  let reddit: RedditClientBroker

  var body: some View {
    NavigationView {
      List {
        ForEach(self.subredditData.subreddits) { subreddit in
          if subreddit == self.subredditData.subreddits.last {
            NavigationLink(destination: PostListView(postsData: .init(), subreddit: subreddit, reddit: self.reddit)) {
              SubredditRowView(subreddit: subreddit, reddit: self.reddit).tapAction {
                self.subreddit = subreddit
              }
            }.onAppear {
              self.loadSubreddits()
            }
          } else {
            NavigationLink(destination: PostListView(postsData: .init(), subreddit: subreddit, reddit: self.reddit)) {
              SubredditRowView(subreddit: subreddit, reddit: self.reddit).tapAction {
                self.subreddit = subreddit
              }
            }
          }
        }
      }
    }.frame(minWidth: 100, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
      .onAppear {
        self.loadSubreddits()
      }
  }

  func loadSubreddits() {
    reddit.subreddits(params: listingParams) { listing in
      if let anchor = listing.after { self.listingParams.after = anchor }
      self.subredditData.subreddits.append(contentsOf: listing.subreddits)
    }
  }
}

// #if DEBUG
// struct SubredditsView_Previews: PreviewProvider {
//  static var previews: some View {
//    SubredditsView(reddit: .init())
//      .previewDevice("MacBookPro15,1")
//      .environmentObject(SubredditData())
//  }
// }
// #endif
