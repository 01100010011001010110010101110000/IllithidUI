//
//  CommentsView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/19/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct CommentsView: View {
  @ObjectBinding var commentData: CommentData
  @State var listingParameters = ListingParams()

  let post: Post
  let reddit: RedditClientBroker

  var body: some View {
    List {
      VStack {
        Text(post.id)
        Text(post.title)
      }
      ForEach(self.commentData.comments) { comment in
        Text(comment.body)
      }
    }.frame(width: 600, height: 400)
      .onAppear {
        self.loadComments()
      }
  }

  func loadComments() {
    reddit.getComments(for: post, parameters: listingParameters)
      .subscribe(on: RunLoop.main)
      .sink { listing in
        self.commentData.comments.append(contentsOf: listing.comments)
      }
  }
}

// #if DEBUG
// struct CommentsView_Previews : PreviewProvider {
//    static var previews: some View {
//        CommentsView()
//    }
// }
// #endif
