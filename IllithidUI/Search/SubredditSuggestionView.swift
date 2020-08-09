//
// SubredditSuggestionView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/8/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct SubredditSuggestionLabel: View {
  let suggestion: Subreddit

  static let CreatedFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
  }()

  var body: some View {
    GroupBox {
      VStack(alignment: .center) {
        SubredditIcon(subreddit: suggestion)
          .overlay(Circle().stroke(Color.white, lineWidth: 4))
          .shadow(radius: 10)
          .frame(width: 256, height: 256)

        HStack {
          Label("\(suggestion.subscribers?.postAbbreviation() ?? "???")", systemImage: "newspaper.fill")
            .help("\(suggestion.subscribers?.description ?? "???") subscribers")
          Spacer()
          Text(suggestion.displayNamePrefixed)
            .bold()
          Spacer()
          Label("\(suggestion.created, formatter: Self.CreatedFormatter)", systemImage: "calendar.badge.clock")
            .help("Created on \(suggestion.created, formatter: Self.CreatedFormatter)")
        }
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
