//
//  PostPreview.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/18/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct PostPreview: View {
  let post: Post
  var body: some View {
    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
  }
}

public extension Post {
  func content() -> some View {
    switch postHint {
    case .`self`:
      return GroupBox {
        Text(selftext)
      }.eraseToAnyView()
    case .link:
      return LinkPreview(link: contentUrl)
        .fixedSize(horizontal: true, vertical: false)
        .eraseToAnyView()
    case .image:
      if !previews.isEmpty {
        return RemoteImage(previews.middle!.url)
          .frame(width: CGFloat(integerLiteral: previews.middle!.width),
                 height: CGFloat(integerLiteral: previews.middle!.height))
          .eraseToAnyView()
      } else {
        // TODO: Replace with proper placeholder image
        return Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
          .scaledToFit()
          .frame(width: 96, height: 96)
          .eraseToAnyView()
      }
    case .hostedVideo:
      return Text("Hosted Video")
        .eraseToAnyView()
    case .richVideo:
      return Text("Rich Video")
        .eraseToAnyView()
    default:
      if selftext.isEmpty {
        return LinkPreview(link: contentUrl)
          .eraseToAnyView()
      } else {
        return Text(selftext)
          .eraseToAnyView()
      }
    }
  }
}
