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
    List {
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
        PostContent(post: post)
      }
      Divider()
      ForEach(self.commentData.comments.filter { wrapper in
        if case .comment = wrapper {
          return commentData.commentState[wrapper.id] == .collapsed ||
            commentData.commentState[wrapper.id] == .expanded
        } else {
          return commentData.commentState[wrapper.id] == .expanded
        }
      }) { wrapper in
        self.viewBuilder(wrapper: wrapper)
      }
    }
    .frame(minWidth: 600, minHeight: 400, maxHeight: .infinity)
    .onAppear {
      self.commentData.loadComments(focusOn: self.focusedComment, context: self.focusedComment != nil ? 2 : nil)
    }
  }

  // TODO: Clean up this abomination
  private func viewBuilder(wrapper: CommentWrapper) -> AnyView {
    if commentData.commentState[wrapper.id] == .expanded {
      switch wrapper {
      case let .comment(comment):
        return CommentRowView(comment: comment)
          .conditionalModifier(focusedComment == comment.id,
                               FocusedCommentModifier())
          .onTapGesture {
            DispatchQueue.main.async {
              withAnimation {
                guard let node = self.commentData.root.first(where: { $0.value?.id == comment.id }) else { return }
                self.collapse(clickedNode: node)
              }
            }
          }
          .eraseToAnyView()
      case let .more(more):
        return MoreCommentsRowView(more: more)
          .onTapGesture {
            self.commentData.loadMoreComments(more: more)
          }
          .eraseToAnyView()
      }
    } else if commentData.commentState[wrapper.id] == .collapsed {
      switch wrapper {
      case let .comment(comment):
        return CollapsedComment(comment: comment)
          .onTapGesture {
            DispatchQueue.main.async {
              withAnimation {
                guard let node = self.commentData.root.first(where: { $0.value?.id == comment.id }) else { return }
                self.expand(clickedNode: node)
              }
            }
          }
          .eraseToAnyView()
      case .more:
        return EmptyView()
          .eraseToAnyView()
      }
    } else {
      return EmptyView()
        .eraseToAnyView()
    }
  }

  private func collapse(clickedNode: Node<CommentWrapper>) {
    clickedNode.traverse(postOrder: { wrappedNode in
      guard let value = wrappedNode.value else { return }
      let state = self.commentData.commentState[value.id]
      let wasClicked = value.id == clickedNode.value?.id
      switch state {
      case .expanded:
        self.commentData.commentState[value.id] = wasClicked ? .collapsed : .parentCollapsed
      case .parentCollapsed:
        if wasClicked { assertionFailure("A comment that was collapsed because a parent was collapsed was clicked") }
      case .collapsed:
        self.commentData.commentState[value.id] = wasClicked ? .expanded : .collapsedParentCollapsed
      case .collapsedParentCollapsed:
        if wasClicked { assertionFailure("A comment that was collapsed because a parent was collapsed was clicked") }
      case .none:
        assertionFailure("A comment without a collapse state was encountered")
      }
    })
  }

  private func expand(clickedNode: Node<CommentWrapper>) {
    clickedNode.traverse(preOrder: { wrappedNode in
      guard let value = wrappedNode.value else { return }
      let state = self.commentData.commentState[value.id]
      let wasClicked = value.id == clickedNode.value?.id
      switch state {
      case .expanded:
        assertionFailure("We are expanding a collapsed comment, we should not encounter any expanded comments")
      case .parentCollapsed:
        self.commentData.commentState[value.id] = .expanded
      case .collapsed:
        if wasClicked { self.commentData.commentState[value.id] = .expanded }
      case .collapsedParentCollapsed:
        self.commentData.commentState[value.id] = .collapsed
      case .none:
        assertionFailure("A comment without a collapse state was encountered")
      }
    }, visitChildren: { node in
      guard let value = node.value else { return true }
      // If we encounter a comment the user collapsed directly, do not expand it or its children
      return self.commentData.commentState[value.id] != .collapsed
    })
  }
}

struct FocusedCommentModifier: ViewModifier {
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
