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
    _commentData = .init(wrappedValue: CommentData(post: post))
    self.post = post
    id = post.id
    focusedComment = commentId
  }

  fileprivate init(from listing: Listing) {
    post = listing.posts.first!
    id = post.id
    _commentData = .init(wrappedValue: CommentData(from: listing))
    focusedComment = nil
  }

  // MARK: Internal

  /// The post to which the comments belong
  let id: Fullname

  let post: Post

  let focusedComment: ID36?

  var body: some View {
    ScrollViewReader { scrollProxy in
      ZStack(alignment: .bottomTrailing) {
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
                  + Text(post.author).usernameStyle(color: authorColor)
                  + Text(" \(post.relativePostTime) ago")
              }
            }
            .id(Self.rootViewId)
            HStack {
              Spacer()
              PostContent(post: post)
              Spacer()
            }
          }

          Divider()

          if !commentData.loadingComments && commentData.comments.isEmpty {
            Text("comments.no.comments")
              .offset(y: 40)
          } else {
            CommentsStack(commentData: commentData, scrollProxy: scrollProxy)
              .padding([.bottom, .horizontal])
              .loadingScreen(isLoading: commentData.comments.isEmpty && commentData.loadingComments,
                             title: "comments.loading",
                             offset: (x: 0, y: 40))
          }
        }
        Button(action: {
          withAnimation {
            scrollProxy.scrollTo(Self.rootViewId)
          }
        }, label: {
          Image(systemName: "chevron.up")
        })
          .keyboardShortcut(.upArrow)
          .keyboardShortcut(.home)
          .shadow(radius: 20)
          .padding()
          .help("Scroll to the top")
      }
      .onAppear {
        commentData.loadComments(focusOn: focusedComment,
                                 context: focusedComment != nil ? 2 : nil)
      }
    }
  }

  // MARK: Private

  private static let rootViewId = "view.root"

  @StateObject private var commentData: CommentData
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

// MARK: - CommentsStack

private struct CommentsStack: View {
  @ObservedObject var commentData: CommentData

  let scrollProxy: ScrollViewProxy

  var body: some View {
    LazyVStack {
      RecursiveView(data: commentData.comments, children: \.replies) { comment, isCollapsed in
        CommentRowView(isCollapsed: isCollapsed, comment: comment)
          .id(comment.id)
          .contextMenu {
            Button("Upvote") {}
            Button("Downvote") {}
            Divider()
            Button("Save") {}
            Divider()
            if let depth = comment.depth ?? 0, depth != 0 {
              Button(action: {
                withAnimation {
                  scrollProxy.scrollTo(comment.parentId.components(separatedBy: "_").last!, anchor: .top)
                }
              }, label: { Label("Parent comment", systemImage: "ellipsis.bubble") })
            }
          }
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
