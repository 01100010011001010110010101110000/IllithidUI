//
// SubredditRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct SubredditRowView: View {
  let subreddit: Subreddit

  var body: some View {
    HStack {
      if let headerImageUrl = subreddit.headerImg {
        WebImage(url: headerImageUrl)
          .resizable()
          .scaledToFit()
          .frame(width: 96, height: 96)
      } else {
        // TODO: Replace with proper placeholder image
        Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
          .scaledToFit()
          .frame(width: 96, height: 96)
      }
      Text(subreddit.displayName)
        .font(.headline)
        .padding(.leading)
        .lineLimit(1)
        .fixedSize()
    }
    .tooltip(subreddit.publicDescription)
  }
}

// #if DEBUG
// struct SubredditRowView_Previews : PreviewProvider {
//    static var previews: some View {
//        SubredditRowView()
//    }
// }
// #endif
