//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
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
    VStack {
      Text("Metadata")
        .font(.title)
      VStack {
        Text("Preview Type: \(post.previewType())")
      }
      Divider()
      ScrollView {
        Text(self.prettyJson ?? "Encoding failure")
      }
    }
    .frame(alignment: .leading)
  }
}

private extension Post {
  func previewType() -> String {
    if postHint == .`self` || isSelf {
      if !selftext.isEmpty {
        return "selftext"
      }
    } else if preview?.redditVideoPreview?.scrubberMediaUrl != nil {
      // This also covers postHint == .hostedVideo or .richVideo
      return "player mp4 video"
    } else if postHint == .image {
      if !previews.isEmpty {
        return "remote image"
      } else {
        return "default image"
      }
    } else if postHint == .link {
      return "link preview"
    } else {
      // There was no post hint or it did not match any prior case
      if !selftext.isEmpty {
        return "selftext fallthrough"
      } else {
        return "link preview fallthrough"
      }
    }
    return "unhandled"
  }
}

// struct PostDebugView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostDebugView()
//    }
// }
