//
// CommentRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct CommentRowView: View {
  let comment: Comment
  private let depth: Int
  private let authorColor: Color

  init(comment: Comment) {
    self.comment = comment
    depth = comment.depth ?? 0
    if comment.canModPost, comment.isSubmitter { authorColor = .purple }
    else if comment.canModPost { authorColor = .green }
    else if comment.isSubmitter { authorColor = .blue }
    else { authorColor = .white }
  }

  var body: some View {
    HStack {
      if depth > 0 {
        RoundedRectangle(cornerRadius: 1.5)
          .foregroundColor(Color(hue: 1.0 / Double(depth), saturation: 1.0, brightness: 1.0))
          .frame(width: 3)
      }

      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text(comment.author)
            .font(.subheadline)
            .fontWeight(.heavy)
            .foregroundColor(authorColor)

          Text("\(comment.ups)")
            .foregroundColor(.orange)
          Spacer()
          Text("\(comment.relativeCommentTime) ago")
        }

        Text(comment.body)
          .font(.body)
          .padding()

        Divider()
          .opacity(1.0)
      }
    }.padding(.leading, 12 * CGFloat(integerLiteral: depth))
  }
}

struct MoreCommentsRowView: View {
  let more: More

  var body: some View {
    HStack {
      if more.depth > 0 {
        RoundedRectangle(cornerRadius: 1.5)
          .foregroundColor(Color(hue: 1.0 / Double(more.depth), saturation: 1.0, brightness: 1.0))
          .frame(width: 3)
      }
      Text("\(more.count) more replies")
      Spacer()
    }
    .padding(.leading, 12 * CGFloat(integerLiteral: more.depth))
  }
}

// TODO: Sync saved and voted state with model
struct CommentActionBar: View {
  @State private var vote: VoteDirection = .clear
  @State private var saved: Bool = false
  let comment: Comment

  init(comment: Comment) {
    self.comment = comment
  }

  var body: some View {
    VStack {
      Button(action: {
        if self.vote == .up {
          self.vote = .clear
          self.comment.clearVote(queue: .global(qos: .utility)) { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.fullname): \(error)")
            }
          }
        } else {
          self.vote = .up
          self.comment.upvote(queue: .global(qos: .utility)) { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error upvoting \(self.comment.fullname): \(error)")
            }
          }
        }
      }) {
        Text("Up")
          .foregroundColor(vote == .up ? .orange : nil)
      }
      Button(action: {
        if self.vote == .down {
          self.vote = .clear
          self.comment.clearVote(queue: .global(qos: .utility)) { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.fullname): \(error)")
            }
          }
        } else {
          self.vote = .down
          self.comment.downvote(queue: .global(qos: .utility)) { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error downvoting \(self.comment.fullname): \(error)")
            }
          }
        }
      }) {
        Text("Down")
          .foregroundColor(vote == .down ? .purple : nil)
      }
      Button(action: {
        if self.saved {
          self.saved = false
          self.comment.unsave(queue: .global(qos: .utility)) { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error unsaving \(self.comment.fullname): \(error)")
            }
          }
        } else {
          self.saved = true
          self.comment.save(queue: .global(qos: .utility)) { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error saving \(self.comment.fullname): \(error)")
            }
          }
        }
      }) {
        Text("Save")
          .foregroundColor(comment.saved ? .green : nil)
      }
      // TODO: Pass binding to enable removing a hidden post
      Button(action: {}) {
        Text("Hide")
          .foregroundColor(.red)
      }
      Button(action: {}) {
        Text("Report")
          .foregroundColor(.red)
      }
      Spacer()
    }
    .onAppear {
      if let likeDirection = self.comment.likes {
        self.vote = likeDirection ? .up : .down
      } else {
        self.vote = .clear
      }
      self.saved = self.comment.saved
    }
  }
}

// #if DEBUG
// struct CommentRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        CommentRowView()
//    }
// }
// #endif
