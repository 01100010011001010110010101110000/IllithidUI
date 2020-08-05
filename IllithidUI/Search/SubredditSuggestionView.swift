//
// SubredditSuggestionView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct SubredditSuggestionLabel: View {
  let suggestion: Subreddit

  var body: some View {
    GroupBox {
      VStack(alignment: .center) {
        Group {
          if let imageUrl = suggestion.communityIcon {
            WebImage(url: imageUrl)
              .placeholder(Image(systemName: "photo.fill"))
              .clipShape(Circle())
              .overlay(Circle().stroke(Color.white, lineWidth: 4))
          } else {
            Image(systemName: "photo.fill")
              .font(.system(size: 48))
          }
        }
        .shadow(radius: 10)
        .frame(width: 256, height: 256)
        Text(suggestion.displayNamePrefixed)
          .bold()
          .padding(.vertical, 5)
        HStack {
          Spacer()
          if !suggestion.publicDescription.isEmpty {
            Text(suggestion.publicDescription)
              .lineLimit(3)
              .help(suggestion.publicDescription)
          }
          Spacer()
        }
      }
      .padding(10)
      .frame(height: 380)
    }
  }
}

// struct SubredditSuggestionLabel_Previews: PreviewProvider {
//    static var previews: some View {
//        SubredditSuggestionLabel()
//    }
// }
