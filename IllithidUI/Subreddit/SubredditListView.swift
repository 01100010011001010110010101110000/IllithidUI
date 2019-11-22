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
  let reddit: Illithid = .shared

  var body: some View {
    NavigationView {
      List {
        ForEach(self.subredditData.subreddits) { subreddit in
          NavigationLink(destination: PostListView(postsData: .init(), subreddit: subreddit)) {
            SubredditRowView(subreddit: subreddit)
              .conditionalModifier(subreddit == self.subredditData.subreddits.last, OnAppearModifier {
                self.loadSubreddits()
              })
          }
        }
      }
      .frame(minWidth: 300)
    }
    .listStyle(SidebarListStyle())
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
