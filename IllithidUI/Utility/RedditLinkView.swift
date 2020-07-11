//
// RedditLinkView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

import Illithid

struct RedditLinkView: View {
  @State private var hover: Bool = false
  let link: URL

  private let icon = Image(named: .redditSquare)
  private let windowManager: WindowManager = .shared

  var body: some View {
    VStack {
      LinkBar(iconIsScaled: $hover, icon: icon, link: link)
        .frame(width: 512)
        .background(Color(.controlBackgroundColor))
        .modifier(RoundedBorder(style: Color(.darkGray),
                                cornerRadius: 8.0, width: 2.0))
        .onHover { entered in
          withAnimation(.easeInOut(duration: 0.7)) {
            hover = entered
          }
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
