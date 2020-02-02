//
// PostFullview.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 1/13/20
//

import Combine
import SwiftUI

import Illithid
import SDWebImageSwiftUI
import Ulithari

struct PostFullview: View {
  let post: Post

  var body: some View {
    VStack {
      if post.domain == "gfycat.com" {
        GfycatView(gfyId: String(post.contentUrl.path.dropFirst()))
          .overlay(MediaStamp(mediaType: "gif")
            .padding([.bottom, .trailing], 4),
                   alignment: .bottomTrailing)
      } else {
        PostPreview(post: post)
      }
    }
  }
}

struct GfycatView: View {
  @ObservedObject var gfyData: GfycatData

  init(gfyId id: String) {
    gfyData = .init(gfyId: id)
  }

  var body: some View {
    VStack {
      if gfyData.item == nil {
        EmptyView()
      } else if gfyData.item!.hasAudio {
        Player(url: gfyData.item!.mp4URL)
          .frame(width: CGFloat(gfyData.item!.width), height: CGFloat(gfyData.item!.height))
      } else {
        Player(url: gfyData.item!.mp4URL)
          .frame(width: CGFloat(gfyData.item!.width), height: CGFloat(gfyData.item!.height))
      }
    }
  }
}

class GfycatData: ObservableObject {
  @Published var item: GfyItem? = nil
  let id: String
  let ulithari: Ulithari = .shared

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

struct ImgurView: View {
  @ObservedObject var imgurData: ImgurData

  init(imageId: String) {
    imgurData = .init(imageId: imageId)
  }

  var body: some View {
    VStack {
      if imgurData.imgurImage == nil {
        EmptyView()
      } else if imgurData.imgurImage!.data.animated {
        if imgurData.imgurImage!.data.hasSound {
          Player(url: imgurData.imgurImage!.data.hls!)
            .frame(width: CGFloat(integerLiteral: imgurData.imgurImage!.data.width),
                   height: CGFloat(integerLiteral: imgurData.imgurImage!.data.height))
        } else {
          Player(url: imgurData.imgurImage!.data.hls!)
            .frame(width: CGFloat(integerLiteral: imgurData.imgurImage!.data.width),
                 height: CGFloat(integerLiteral: imgurData.imgurImage!.data.height))
        }
      } else {
        WebImage(url: imgurData.imgurImage!.data.link)
          .frame(width: CGFloat(integerLiteral: imgurData.imgurImage!.data.width),
               height: CGFloat(integerLiteral: imgurData.imgurImage!.data.height))
      }
    }
  }
}

class ImgurData: ObservableObject {
  @Published var imgurImage: ImgurImage? = nil
  let ulithari: Ulithari = .shared

  init(imageId: String) {
    ulithari.fetchImgurImage(id: imageId, queue: .global(qos: .userInteractive)) { result in
      switch result {
      case let .success(imgurImage):
        DispatchQueue.main.async {
          self.imgurImage = imgurImage
        }
      case let .failure(error):
        print("Failed to fetch \(imageId) data: \(error)")
      }
    }
  }
}

// struct PostFullview_Previews: PreviewProvider {
//    static var previews: some View {
//        PostFullview()
//    }
// }
