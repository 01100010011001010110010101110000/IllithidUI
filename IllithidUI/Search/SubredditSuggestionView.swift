//
// SubredditSuggestionView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/22/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct SubredditSuggestionLabel: View {
  let suggestion: Subreddit
  var body: some View {
    Text(suggestion.displayName)
  }
}

// struct SubredditSuggestionLabel_Previews: PreviewProvider {
//    static var previews: some View {
//        SubredditSuggestionLabel()
//    }
// }
