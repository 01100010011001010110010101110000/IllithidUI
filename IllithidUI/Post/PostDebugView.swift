//
// PostDebugView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

import Illithid

struct PostDebugView: View, Identifiable {
  let post: Post
  let id: String
  private var encoder = JSONEncoder()
  let prettyJson: String?

  init(post: Post) {
    self.post = post
    id = post.id
    encoder.dateEncodingStrategy = .secondsSince1970
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    if let data = try? encoder.encode(post) {
      prettyJson = String(data: data, encoding: .utf8)
    } else {
      prettyJson = nil
    }
  }

  var body: some View {
    VStack {
      Text("Metadata")
        .font(.title)
      VStack {
        Text("Preview Type: \(post.previewGuess.rawValue)")
      }
      Divider()
      ScrollView {
        Text(prettyJson ?? "Encoding failure")
      }
    }
    .frame(alignment: .leading)
  }
}

// struct PostDebugView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostDebugView()
//    }
// }
