//
// SubredditListView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/9/20
//

import SwiftUI

import Illithid
import Willow

struct SubredditsView: View {
  @ObservedObject var subredditData: SubredditListData

  var body: some View {
    NavigationView {
      List {
        ForEach(subredditData.subreddits) { subreddit in
          NavigationLink(destination: PostListView(postContainer: subreddit)) {
            SubredditRowView(subreddit: subreddit)
              .conditionalModifier(subreddit == subredditData.subreddits.last, OnAppearModifier {
                subredditData.loadSubreddits()
              })
          }
        }
      }
      .frame(minWidth: 300)

      NavigationPrompt(prompt: "Choose a subreddit")
    }
    .listStyle(SidebarListStyle())
    .onAppear {
      subredditData.loadSubreddits()
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
