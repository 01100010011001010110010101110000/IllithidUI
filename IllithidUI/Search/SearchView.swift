//
// SearchView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

import Illithid

struct SearchView: View {
  @StateObject var searchData: SearchData = .init()

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
          if !searchData.suggestions.isEmpty {
            ForEach(searchData.suggestions) { suggestion in
              NavigationLink(
                destination: PostListView(postContainer: suggestion),
                label: {
                  SubredditSuggestionLabel(suggestion: suggestion)
                }
              )
            }
          }
          // TODO: Move these into dedicated search areas
//          if !searchData.subreddits.isEmpty {
//            Section(header: Text("Subreddits").font(.headline)) {
//              ForEach(searchData.subreddits) { subreddit in
//                NavigationLink(destination: PostListView(data: self.searchData.postContainer(for: subreddit))) {
//                  Text(subreddit.displayName)
//                }
//              }
//            }
//          }
//
//          if !searchData.accounts.isEmpty {
//            Section(header: Text("Users").font(.headline)) {
//              ForEach(searchData.accounts) { account in
//                Text(account.name)
//              }
//            }
//          }
//
//          if !searchData.posts.isEmpty {
//            Section(header: Text("Posts").font(.headline)) {
//              ForEach(searchData.posts) { post in
//                NavigationLink(destination: CommentsView(post: post)) {
//                  Text(post.title)
//                }
//              }
//            }
//          }
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
