//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import Combine
import SwiftUI

import Illithid
import Ulithcat

struct PostFullview: View {
  let post: Post

  var body: some View {
    VStack {
      if post.domain == "gfycat.com" {
        GfycatFullview(gfyId: String(post.contentUrl.path.dropFirst()))
        .overlay(MediaStamp(mediaType: "gif")
         .padding([.bottom, .trailing], 4),
        alignment: .bottomTrailing)
      } else {
        PostPreview(post: post)
      }
    }
  }
}

private struct GfycatFullview: View {
  @ObservedObject var gfyData: GfycatData

  init(gfyId id: String) {
    gfyData = .init(gfyId: id)
  }

  var body: some View {
    VStack {
      if gfyData.item == nil {
        EmptyView()
      } else {
        Player(url: gfyData.item!.mp4URL)
          .frame(width: CGFloat(gfyData.item!.width), height: CGFloat(gfyData.item!.height))
      }
    }
  }
}

private class GfycatData: ObservableObject {
  @Published var item: GfyItem? = nil
  let id: String
  let ulithari: Ulithcat = .init()

  init(gfyId id: String) {
    self.id = id
    ulithari.fetchGfycat(id: id, queue: .global(qos: .userInteractive)) { result in
      switch result {
      case let .success(item):
        DispatchQueue.main.async {
          self.item = item
        }
      case let .failure(error):
        print("Failed to fetch gfyitem: \(error)")
      }
    }
  }
}

// struct PostFullview_Previews: PreviewProvider {
//    static var previews: some View {
//        PostFullview()
//    }
// }
