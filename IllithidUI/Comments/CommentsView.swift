//
//  CommentsView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/19/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import Illithid

struct CommentsView: View {
  @ObjectBinding var commentData: CommentData
  @State var listingParameters = ListingParameters(limit: 100)

  let post: Post
  let reddit: RedditClientBroker

  var body: some View {
    List {
      VStack {
        Text(post.id)
        Text(post.title)
      }
      ForEach(self.commentData.allComments) { comment in
        VStack(alignment: .leading, spacing: 0) {
          Text(comment.author)
            .font(.subheadline)
            .fontWeight(.heavy)
          Text(comment.body)
            .font(.body)
            .lineLimit(nil)
          Divider()
        }.offset(x: 20 * Length(integerLiteral: comment.depth ?? 0))
      }
    }.frame(minWidth: 600, maxWidth: 1000, minHeight: 400, maxHeight: .infinity, alignment: .leading)
      .onAppear {
        self.loadComments()
      }
  }

  func loadComments() {
    _ = reddit.comments(for: post, parameters: listingParameters)
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
