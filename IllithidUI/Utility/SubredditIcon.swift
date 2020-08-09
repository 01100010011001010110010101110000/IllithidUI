//
// SubredditIcon.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/9/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct SubredditIcon: View {
  let subreddit: Subreddit

  var body: some View {
    if let imageUrl = subreddit.communityIcon {
      WebImage(url: imageUrl)
        .renderingMode(.original)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .clipShape(Circle())
    } else {
      Circle()
        .foregroundColor(circleColor())
        // TODO: Resize text depending on the size of the circle
        .overlay(Text("\(String(subreddit.displayName.first!.uppercased()))"))
    }
  }

  private func circleColor() -> Color {
    // TODO: This should generate a variety, ideally sticking to a theme
    Color(hue: 1.0 / Double(subreddit.displayName.hashValue.magnitude % 360), saturation: 1.0, brightness: 1.0)
  }
}

// struct SubredditIconView_Previews: PreviewProvider {
//  static var previews: some View {
//    SubredditIconView()
//  }
// }
