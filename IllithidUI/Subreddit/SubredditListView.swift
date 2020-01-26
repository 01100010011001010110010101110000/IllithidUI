//
// SubredditListView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid
import Willow

struct SubredditsView: View {
  @ObservedObject var subredditData: SubredditData

  var body: some View {
    NavigationView {
      List {
        ForEach(self.subredditData.subreddits) { subreddit in
          NavigationLink(destination: PostListView(postContainer: subreddit)) {
            SubredditRowView(subreddit: subreddit)
              .conditionalModifier(subreddit == self.subredditData.subreddits.last, OnAppearModifier {
                self.subredditData.loadSubreddits()
              })
          }
        }
      }
      .frame(minWidth: 300)
    }
    .listStyle(SidebarListStyle())
    .onAppear {
      self.subredditData.loadSubreddits()
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
