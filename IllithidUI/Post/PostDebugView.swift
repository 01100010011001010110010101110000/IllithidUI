//
// PostDebugView.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
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
