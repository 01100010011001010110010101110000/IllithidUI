//
// CommentRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct CommentRowView: View {
  @ObservedObject var moderators: ModeratorData = .shared

  let comment: Comment
  private let depth: Int
  private var authorColor: Color {
    if moderators.isModerator(username: comment.author, ofSubreddit: comment.subreddit) {
      return .green
    } else if comment.isSubmitter {
      return .blue
    }
    else {
      return .white
    }
  }

  init(comment: Comment) {
    self.comment = comment
    depth = comment.depth ?? 0
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

          Text(comment.scoreHidden ? "-" : String(comment.ups.postAbbreviation(1)))
            .foregroundColor(.orange)
          Spacer()
          Text("\(comment.relativeCommentTime) ago")
        }

        Text(comment.body)
          .font(.body)
          .padding()

        CommentActionBar(comment: comment)
          .padding(.bottom, 5)

        Divider()
          .opacity(1.0)
      }
    }
    .padding(.leading, 12 * CGFloat(integerLiteral: depth))
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
      Text("\(more.count) more \(more.count == 1 ? "reply" : "replies")")
        .font(.footnote)
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

  var body: some View {
    HStack {
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(vote == .up ? .orange : Color(.darkGray))
        .overlay(Text("Up"), alignment: .center)
        .foregroundColor(.white)
        .onTapGesture {
          if self.vote == .up {
            self.vote = .clear
            self.comment.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.author) - \(self.comment.fullname): \(error)")
              }
            }
          } else {
            self.vote = .up
            self.comment.upvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.author) - \(self.comment.fullname): \(error)")
              }
            }
          }
        }
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(vote == .down ? .purple : Color(.darkGray))
        .overlay(Text("Down"), alignment: .center)
        .foregroundColor(.white)
        .onTapGesture {
          if self.vote == .down {
            self.vote = .clear
            self.comment.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.author) - \(self.comment.fullname): \(error)")
              }
            }
          } else {
            self.vote = .down
            self.comment.downvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.author) - \(self.comment.fullname): \(error)")
              }
            }
          }
        }
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(saved ? .green : Color(.darkGray))
        .overlay(Text("Save"), alignment: .center)
        .foregroundColor(.white)
        .onTapGesture {
          self.saved.toggle()
          if self.saved {
            self.comment.save { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.author) - \(self.comment.fullname): \(error)")
              }
            }
          } else {
            self.comment.unsave { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.comment.author) - \(self.comment.fullname): \(error)")
              }
            }
          }
        }
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(.red)
        .overlay(Text("Hide"), alignment: .center)
        .foregroundColor(.white)
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(.red)
        .overlay(Text("Report"), alignment: .center)
        .foregroundColor(.white)
        .frame(width: 32, height: 32)
      Spacer()
    }
    .padding(10)
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
