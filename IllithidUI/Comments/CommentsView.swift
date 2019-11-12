//
//  CommentsView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/19/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import AlamofireImage
import Illithid

struct CommentsView: IdentifiableView {
  @ObservedObject var commentData: CommentData
  @State private var listingParameters = ListingParameters(limit: 100)

  /// The shared `ImageDownloader` to use to fetch images linked in the comments
  /// - Note: This is probably a poor way of doing this, but will suffice until I figure out a better way of bridging `EnvironmentObject` across windows.
  ///        The `ImageDownloader` instantiated in the `AppDelegate` will live for the lifetime of the app.
  let imageDownloader: ImageDownloader = (NSApp.delegate! as! AppDelegate).imageDownloader

  let illithid: Illithid = .shared

  /// The post to which the comments belong
  let id: Fullname

  let post: Post

  init(commentData: CommentData, post: Post) {
    self.commentData = commentData
    self.post = post
    id = post.id
  }

  var body: some View {
    List {
      VStack(alignment: .center) {
        Text(post.title).font(.largeTitle)
        post.content()
      }
      Divider().opacity(1.0)
      ForEach(self.commentData.allComments) { comment in
        CommentRowView(comment: comment)
      }
    }.frame(minWidth: 600, maxWidth: 1000, minHeight: 400, maxHeight: .infinity, alignment: .leading)
      .onAppear {
        self.loadComments()
      }
      .environmentObject(imageDownloader)
  }

  func loadComments() {
    _ = illithid.comments(for: post, parameters: listingParameters)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { _ in

      }) { listing in
        self.commentData.comments.append(contentsOf: listing.comments)
      }
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
