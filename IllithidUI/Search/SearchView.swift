//
// SearchView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

import Illithid

struct SearchView: View {
  @StateObject var searchData: SearchData = .init()

  let columns: [GridItem] = [
    GridItem(.adaptive(minimum: 320)),
  ]

  var prompt: String {
    if searchData.query.isEmpty { return "Make a search" }
    else if searchData.suggestions.isEmpty { return "No subreddits found" }
    else { return "Open a subreddit" }
  }

  var body: some View {
    VStack {
      TextField("Search Reddit", text: $searchData.query) {
        // Allows the user to force a search for a string shorter than 3 characters
        _ = self.searchData.search(for: self.searchData.query)
      }
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .padding()

      ScrollView {
        LazyVGrid(columns: columns) {
          ForEach(searchData.suggestions) { suggestion in
            SubredditSuggestionLabel(suggestion: suggestion)
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
