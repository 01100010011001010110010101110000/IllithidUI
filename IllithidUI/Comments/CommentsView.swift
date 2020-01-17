//
// CommentsView.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import SwiftUI

import AlamofireImage
import Illithid

struct CommentsView: IdentifiableView {
  @ObservedObject var commentData: CommentData

  /// The shared `ImageDownloader` to use to fetch images linked in the comments
  /// - Note: This is probably a poor way of doing this, but will suffice until I figure out a better way of bridging `EnvironmentObject` across windows.
  ///        The `ImageDownloader` instantiated in the `AppDelegate` will live for the lifetime of the app.
  let imageDownloader: ImageDownloader = (NSApp.delegate! as! AppDelegate).imageDownloader

  /// The post to which the comments belong
  let id: Fullname

  let post: Post

  init(post: Post) {
    commentData = CommentData(post: post)
    self.post = post
    id = post.id
  }

  var body: some View {
    List {
      VStack(alignment: .leading) {
        PostFullview(post: post)
        Text(post.title)
          .font(.largeTitle)
      }
      Divider()
        .opacity(1.0)
      ForEach(self.commentData.allComments) { comment in
        CommentRowView(comment: comment)
          .frame(alignment: .leading)
      }
    }
    .frame(minWidth: 600, minHeight: 400, maxHeight: .infinity)
    .onAppear {
      self.commentData.loadComments()
    }
    .environmentObject(imageDownloader)
  }
}

// #if DEBUG
// struct CommentsView_Previews: PreviewProvider {
//  static var previews: some View {
//    let testCommentsPath = Bundle.main.path(forResource: "comments", ofType: "json")!
//    let data = try! Data(contentsOf: URL(fileURLWithPath: testCommentsPath))
//    let decoder = JSONDecoder()
//    let listing = try! decoder.decode(Listing.self, from: data)
//
//    return CommentsView(commentData: .init(from: listing), reddit: .init(configuration: IllithidConfiguration()))
//  }
// }
// #endif
