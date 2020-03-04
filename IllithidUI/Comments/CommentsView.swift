//
// CommentsView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import SwiftUI

import Illithid

struct CommentsView: View, Identifiable {
  @ObservedObject var commentData: CommentData

  /// The post to which the comments belong
  let id: Fullname

  let post: Post

  init(post: Post) {
    commentData = CommentData(post: post)
    self.post = post
    id = post.id
  }

  fileprivate init(from listing: Listing) {
    post = listing.posts.first!
    id = post.id
    commentData = CommentData(from: listing)
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
            Text("in \(post.subreddit) by ")
              + Text(post.author)
              .foregroundColor(.blue)
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

  // TODO: Clean up this abomination
  func viewBuilder(wrapper: CommentWrapper) -> AnyView {
    if commentData.showComment[wrapper.id] == .expanded {
      switch wrapper {
      case let .comment(comment):
        return CommentRowView(comment: comment)
          .onTapGesture {
            DispatchQueue.main.async {
              withAnimation {
                guard let node = self.commentData.root.first(where: { $0.value?.id == comment.id }) else { return }
                node.traverse(postOrder: { wrappedNode in
                  guard let value = wrappedNode.value else { return }
                  let state = self.commentData.showComment[value.id]
                  let wasClicked = value.id == comment.id
                  switch state {
                  case .expanded:
                    if wasClicked { self.commentData.showComment[value.id] = .collapsed }
                    else { self.commentData.showComment[value.id] = .parentCollapsed }
                  case .parentCollapsed:
                    if wasClicked { assertionFailure("A comment that was collapsed because a parent was collapsed was clicked") }
                  case .collapsed:
                    if wasClicked { self.commentData.showComment[value.id] = .expanded }
                    else { self.commentData.showComment[value.id] = .collapsedParentCollapsed }
                  case .collapsedParentCollapsed:
                    if wasClicked { assertionFailure("A comment that was collapsed because a parent was collapsed was clicked") }
                  case .none:
                    assertionFailure("A comment without a collapse state was encountered")
                  }
                })
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
    } else if commentData.showComment[wrapper.id] == .collapsed {
      switch wrapper {
      case let .comment(comment):
        return HStack {
          if (comment.depth ?? 0) > 0 {
            RoundedRectangle(cornerRadius: 1.5)
              .foregroundColor(Color(hue: 1.0 / Double(comment.depth ?? 0), saturation: 1.0, brightness: 1.0))
              .frame(width: 3)
          }
          Text(comment.author)
            .font(.subheadline)
            .fontWeight(.heavy)
          Spacer()
        }
        .padding(.leading, 12 * CGFloat(integerLiteral: comment.depth ?? 0))
        .onTapGesture {
          DispatchQueue.main.async {
            withAnimation {
              guard let node = self.commentData.root.first(where: { $0.value?.id == comment.id }) else { return }
              node.traverse(preOrder: { wrappedNode in
                guard let value = wrappedNode.value else { return }
                let state = self.commentData.showComment[value.id]
                let wasClicked = value.id == comment.id
                switch state {
                case .expanded:
                  assertionFailure("We are expanding a collapsed comment, we should not encounter any expanded comments")
                case .parentCollapsed:
                  self.commentData.showComment[value.id] = .expanded
                case .collapsed:
                  if wasClicked { self.commentData.showComment[wrapper.id] = .expanded }
                case .collapsedParentCollapsed:
                  self.commentData.showComment[value.id] = .collapsed
                case .none:
                  assertionFailure("A comment without a collapse state was encountered")
                }
              }, visitChildren: { node in
                guard let value = node.value else { return true }
                return self.commentData.showComment[value.id] != .collapsed
              })
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
