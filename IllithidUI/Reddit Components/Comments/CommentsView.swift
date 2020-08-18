//
// CommentsView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import Combine
import SwiftUI

import Illithid

struct CommentsView: View, Identifiable {
  @ObservedObject var commentData: CommentData
  @ObservedObject private var moderators: ModeratorData = .shared

  /// The post to which the comments belong
  let id: Fullname

  let post: Post

  let focusedComment: ID36?

  private var authorColor: Color {
    if post.isAdminPost {
      return .red
    } else if moderators.isModerator(username: post.author, ofSubreddit: post.subreddit) {
      return .green
    } else {
      return .blue
    }
  }

  init(post: Post, focusOn commentId: ID36? = nil) {
    commentData = CommentData(post: post)
    self.post = post
    id = post.id
    focusedComment = commentId
  }

  fileprivate init(from listing: Listing) {
    post = listing.posts.first!
    id = post.id
    commentData = CommentData(from: listing)
    focusedComment = nil
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack {
          Text(post.title)
            .font(.largeTitle)
            .multilineTextAlignment(.center)
            .heightResizable()
          Spacer()
          VStack {
            Text("in \(post.subreddit) by ")
              + Text(post.author)
              .usernameStyle(color: authorColor)
            Text("\(post.relativePostTime) ago")
          }
        }
        HStack {
          Spacer()
          PostContent(post: post)
          Spacer()
        }
      }
      Divider()
      LazyVStack {
        RecursiveView(data: commentData.comments, children: \.replies) { comment in
          CommentRowView(comment: comment)
        } footer: { comment in
          if let more = comment.more {
            MoreCommentsRowView(more: more)
              .onLongPressGesture {
                commentData.expandMore(more: more)
              }
          }
        }

        if let more = commentData.rootMore {
          MoreCommentsRowView(more: more)
            .onLongPressGesture {
              commentData.expandMore(more: more)
            }
        }
      }
      .padding([.bottom, .horizontal])
    }
    .onAppear {
      self.commentData.loadComments(focusOn: self.focusedComment,
                                    context: self.focusedComment != nil ? 2 : nil)
    }
  }
}

private struct FocusedCommentModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.overlay(
      Rectangle()
        .foregroundColor(.white)
        .opacity(0.25)
    )
  }
}

struct CommentsView_Previews: PreviewProvider {
  static var previews: some View {
    let testCommentsPath = Bundle.main.path(forResource: "comments", ofType: "json")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: testCommentsPath))
    let decoder = JSONDecoder()
    let listing = try! decoder.decode(Listing.self, from: data)

    return CommentsView(from: listing)
  }
}
