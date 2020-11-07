// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import Combine
import SwiftUI

import Illithid

// MARK: - CommentsView

struct CommentsView: View, Identifiable {
  // MARK: Lifecycle

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

  // MARK: Internal

  @ObservedObject var commentData: CommentData
  /// The post to which the comments belong
  let id: Fullname

  let post: Post

  let focusedComment: ID36?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack {
          Text(post.title)
            .font(.largeTitle)
            .multilineTextAlignment(.center)
            .padding([.horizontal, .top])
            .heightResizable()
          Spacer()
          VStack {
            Text("in \(post.subreddit) by ")
              + Text(post.author)
              .usernameStyle(color: authorColor)
              + Text("\(post.relativePostTime) ago")
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
        RecursiveView(data: commentData.comments, children: \.replies) { comment, isCollapsed in
          CommentRowView(isCollapsed: isCollapsed, comment: comment)
          if let more = comment.more, more.isThreadContinuation {
            MoreCommentsRowView(more: more)
              .onTapGesture {
                commentData.expandMore(more: more)
              }
          }
        } footer: { comment in
          if let more = comment.more, more.id != More.continueThreadId {
            MoreCommentsRowView(more: more)
              .onTapGesture {
                commentData.expandMore(more: more)
              }
          }
        }

        if let more = commentData.rootMore {
          MoreCommentsRowView(more: more)
            .onTapGesture {
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

  // MARK: Private

  @ObservedObject private var moderators: ModeratorData = .shared

  private var authorColor: Color {
    if post.isAdminPost {
      return .red
    } else if moderators.isModerator(username: post.author, ofSubreddit: post.subreddit) {
      return .green
    } else {
      return .blue
    }
  }
}

// MARK: - FocusedCommentModifier

private struct FocusedCommentModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.overlay(
      Rectangle()
        .foregroundColor(.white)
        .opacity(0.25)
    )
  }
}

// MARK: - CommentsView_Previews

struct CommentsView_Previews: PreviewProvider {
  static var previews: some View {
    let testCommentsPath = Bundle.main.path(forResource: "comments", ofType: "json")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: testCommentsPath))
    let decoder = JSONDecoder()
    let listing = try! decoder.decode(Listing.self, from: data)

    return CommentsView(from: listing)
  }
}
