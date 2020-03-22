//
// RedditLinkView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

import Illithid

struct RedditLinkView: View {
  let link: URL

  private let icon = Image(named: .redditSquare)
  private let windowManager: WindowManager = .shared

  var body: some View {
    VStack {
      LinkBar(icon: icon, link: link)
        .frame(width: 512)
        .background(Color(.controlBackgroundColor))
        .modifier(RoundedBorder(style: Color(.darkGray),
                                cornerRadius: 8.0, width: 2.0))
        .onTapGesture {
          self.openRedditLink(link: self.link)
        }
    }
  }

  private func openRedditLink(link: URL) {
    windowManager.openRedditLink(link: link)
  }
}

// struct RedditLinkView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedditLinkView()
//    }
// }
