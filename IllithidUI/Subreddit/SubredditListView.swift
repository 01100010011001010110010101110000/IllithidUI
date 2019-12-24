//
// SubredditListView.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
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
          NavigationLink(destination: PostListView(postContainer: subreddit)) {
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
