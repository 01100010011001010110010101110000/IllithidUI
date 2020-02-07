//
// CommentsView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import SwiftUI

import Illithid

struct CommentsView: IdentifiableView {
  @ObservedObject var commentData: CommentData

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
        PostContent(post: post)
        HStack {
          Text(post.title)
            .font(.largeTitle)
          Spacer()
          VStack {
            Text("in \(post.subreddit) by \(post.author)")
            Text("\(post.relativePostTime) ago")
          }
        }
      }
      Divider()
        .opacity(1.0)
      ForEach(self.commentData.comments) { comment in
        self.viewBuilder(wrapper: comment)
      }
    }
    .frame(minWidth: 600, minHeight: 400, maxHeight: .infinity)
    .onAppear {
      self.commentData.loadComments()
    }
  }
  func viewBuilder(wrapper: CommentWrapper) -> AnyView {
    switch wrapper {
    case let .comment(comment):
      return CommentRowView(comment: comment)
        .eraseToAnyView()
    case let .more(more):
      return HStack {
        if more.depth > 0 {
          RoundedRectangle(cornerRadius: 1.5)
            .foregroundColor(Color(hue: 1.0 / Double(more.depth), saturation: 1.0, brightness: 1.0))
            .frame(width: 3)
        }
        Text("\(more.count) more replies")
        Spacer()
      }
      .padding(.leading, 20 * CGFloat(integerLiteral: more.depth))
      .eraseToAnyView()
    }
  }
}

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
