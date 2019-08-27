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
  @ObservedObject var subredditData: SubredditData
  @State private var subreddit: Subreddit? = nil
  let reddit: RedditClientBroker = .shared

  var body: some View {
    // NavigationView seems to be bugged
    HSplitView {
      List {
        ForEach(self.subredditData.subreddits) { subreddit in
          ZStack(alignment: .leading) {
            SubredditRowView(subreddit: subreddit)
              .padding(.leading)
              .conditionalModifier(subreddit == self.subredditData.subreddits.last, OnAppearModifier {
                self.loadSubreddits()
              })
              .onTapGesture {
                self.subreddit = subreddit
              }
            Spacer() // Correct alignment issue post beta 5
            if subreddit == self.subreddit {
              Rectangle()
                .foregroundColor(Color.secondary.opacity(0.1))
            }
          }
        }
      }
      if self.subreddit != nil {
        PostListView(postsData: .init(), subreddit: self.subreddit!)
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
