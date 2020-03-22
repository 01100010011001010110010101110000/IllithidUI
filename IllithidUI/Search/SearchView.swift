//
// SearchView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

import Illithid

struct SearchView: View {
  @ObservedObject var searchData: SearchData

  var body: some View {
    VStack {
      TextField("Search Reddit", text: $searchData.query) {
        // Allows the user to force a search for a string shorter than 3 characters
        _ = self.searchData.search(for: self.searchData.query)
      }
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .padding()
      NavigationView {
        List {
          if !searchData.subreddits.isEmpty {
            Section(header: Text("Subreddits").font(.headline)) {
              ForEach(searchData.subreddits) { subreddit in
                NavigationLink(destination: PostListView(postContainer: subreddit)) {
                  Text(subreddit.displayName)
                }
              }
            }
          }

          if !searchData.accounts.isEmpty {
            Section(header: Text("Users").font(.headline)) {
              ForEach(searchData.accounts) { account in
                Text(account.name)
              }
            }
          }

          if !searchData.posts.isEmpty {
            Section(header: Text("Posts").font(.headline)) {
              ForEach(searchData.posts) { post in
                NavigationLink(destination: CommentsView(post: post)) {
                  Text(post.title)
                }
              }
            }
          }
        }
      }
    }
  }
}

// #if DEBUG
// struct SearchView_Previews : PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
// }
// #endif
