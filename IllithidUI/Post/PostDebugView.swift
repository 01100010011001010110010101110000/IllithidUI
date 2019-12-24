//
//  PostDebugView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 12/20/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct PostDebugView: IdentifiableView {
  let post: Post
  let id: String
  private var encoder = JSONEncoder()
  let prettyJson: String?

  init(post: Post) {
    self.post = post
    id = post.id
    encoder.dateEncodingStrategy = .secondsSince1970
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    if let data = try? encoder.encode(post) {
      prettyJson = String(data: data, encoding: .utf8)
    } else {
      prettyJson = nil
    }
  }

  var body: some View {
    ScrollView {
      Text(self.prettyJson ?? "Encoding failure")
    }
  }
}

// struct PostDebugView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostDebugView()
//    }
// }
