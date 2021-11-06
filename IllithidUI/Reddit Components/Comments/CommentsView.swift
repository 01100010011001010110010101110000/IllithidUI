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

  /// The `Fullname` of the post to which the comments belong
  let id: Fullname

  /// The post to which the comments belong
  let post: Post

  /// The `ID36` of the comment which should be focused
  let focusedComment: ID36?

  var body: some View {
    ScrollViewReader { scrollProxy in
      VStack {
        HStack {
          SortController(model: sorter, hideIntervalPicker: true)
            .onReceive(sorter.$sort.dropFirst()) { sort in
              commentData.reload(focusOn: focusedComment, context: commentContext, sort: sort)
            }

          RefreshButton {
            commentData.reload(focusOn: focusedComment, context: commentContext, sort: sorter.sort)
          }
          .keyboardShortcut("r")

          Spacer()
        }
        .padding([.top, .leading], 10)

        ZStack(alignment: .bottomTrailing) {
          ScrollView {
            DetailedPostView(post: post)
              .id(Self.rootViewId)
              .padding(.leading)

            Divider()

            if !commentData.loadingComments && commentData.comments.isEmpty {
              Text("comments.no.comments")
                .offset(y: 40)
            } else {
              CommentsStack(commentData: commentData, scrollProxy: scrollProxy)
                .padding([.bottom])
                .padding(.horizontal, 5)
                .loadingScreen(isLoading: commentData.comments.isEmpty && commentData.loadingComments,
                               title: "comments.loading",
                               offset: (x: 0, y: 40))
            }
          }
          HStack(spacing: 5) {
            Button(action: {
              if let lastComment = commentData.comments.last {
                withAnimation {
                  scrollProxy.scrollTo(lastComment.id, anchor: .top)
                }
              }
            }, label: {
              VStack {
                Image(systemName: "chevron.down")
                Image(systemName: "chevron.down")
                  .offset(y: -2)
              }
              .offset(y: -3)
            })
            .keyboardShortcut(.downArrow)
            .shadow(radius: 20)
            .help("comments.scroll.bottom")

            Button(action: {
              withAnimation {
                scrollProxy.scrollTo(Self.rootViewId, anchor: .top)
              }
            }, label: {
              VStack {
                Image(systemName: "chevron.up")
                Image(systemName: "chevron.up")
                  .offset(y: -2)
              }
              .offset(y: -3)
            })
            .keyboardShortcut(.upArrow)
            .shadow(radius: 20)
            .help("comments.scroll.top")
          }
          .padding()
        }
        .onAppear {
          commentData.loadComments(focusOn: focusedComment, context: commentContext, sort: sorter.sort)
        }
      }
    }
  }

  // MARK: Private

  private static let rootViewId = "view.root"

  @StateObject private var commentData: CommentData
  // TODO: Setup a user preference to choose a specific static sort, or to respect the Subreddit sort
  @StateObject private var sorter = SortModel(sort: CommentsSort.best, topInterval: .day)
  @ObservedObject private var moderators: ModeratorData = .shared

  private var commentContext: Int? {
    focusedComment != nil ? 2 : nil
  }

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
        CommentRowView(isCollapsed: isCollapsed, comment: comment, scrollProxy: scrollProxy)
          .id(comment.id)
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
