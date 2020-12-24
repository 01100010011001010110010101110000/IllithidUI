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

import SwiftUI

import Illithid

// MARK: - CommentRowView

struct CommentRowView: View {
  @State private var textSize: CGRect = .zero
  @Binding var isCollapsed: Bool

  let comment: Comment

  var body: some View {
    VStack {
      Group {
        if comment.isRemoved {
          RemovedComment(isCollapsed: $isCollapsed, comment: comment)
        } else if comment.isDeleted {
          DeletedComment(isCollapsed: $isCollapsed, comment: comment)
        } else {
          VStack(alignment: .leading) {
            AuthorBar(comment: comment)
              .padding(.leading, 4)

            if !isCollapsed {
              AttributedText(attributed: comment.attributedBody)
              CommentActionBar(comment: comment)
                .padding(.bottom, 5)
            }
          }
        }
      }
      .padding(.trailing)
      .offset(x: 10)
      .overlay(
        HStack {
          CommentColorBar(isCollapsed: $isCollapsed, for: comment)
          Spacer()
        }
      )
      Divider()
    }
    .padding(.leading, 12 * CGFloat(integerLiteral: comment.depth ?? 0))
  }
}

// MARK: - RemovedComment

private struct RemovedComment: View {
  @Binding var isCollapsed: Bool

  let comment: Comment

  var body: some View {
    HStack {
      Text("Removed by moderator")
      Spacer()
      Text("\(comment.relativeCommentTime) ago")
      Image(systemName: "chevron.down")
        .animation(.easeIn)
        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
        .onTapGesture {
          withAnimation {
            isCollapsed.toggle()
          }
        }
    }
  }
}

// MARK: - DeletedComment

private struct DeletedComment: View {
  @Binding var isCollapsed: Bool

  let comment: Comment

  var body: some View {
    VStack(alignment: .leading) {
      AuthorBar(comment: comment)
      if !isCollapsed {
        Text("Deleted by author")
      }
    }
  }
}

// MARK: - AuthorBar

private struct AuthorBar: View {
  // MARK: Lifecycle

  init(comment: Comment) {
    self.comment = comment
  }

  // MARK: Internal

  let comment: Comment

  var body: some View {
    HStack {
      Text(comment.author)
        .usernameStyle(color: authorColor)
      Text(comment.scoreHidden ? "-" : String(comment.ups.postAbbreviation(1)))
        .foregroundColor(.orange)
      Spacer()
      Text("\(comment.relativeCommentTime) ago")
    }
  }

  // MARK: Private

  @ObservedObject private var moderators: ModeratorData = .shared

  private var authorColor: Color {
    if comment.isAdminComment {
      return .red
    } else if moderators.isModerator(username: comment.author, ofSubreddit: comment.subreddit) {
      return .green
    } else if comment.isSubmitter {
      return .blue
    } else {
      return .white
    }
  }
}

// MARK: - MoreCommentsRowView

struct MoreCommentsRowView: View {
  let more: More

  var body: some View {
    HStack {
      CommentColorBar(for: more)

      // This represents a thread continuation
      if more.isThreadContinuation {
        Text("Continue this thread\u{2026}")
      } else {
        Text("\(more.count) more \(more.count == 1 ? "reply" : "replies")")
      }

      Spacer()
    }
    .padding(.leading, 12 * CGFloat(integerLiteral: more.depth))
  }
}

// MARK: - CommentActionBar

// TODO: Sync saved and voted state with model
struct CommentActionBar: View {
  // MARK: Lifecycle

  init(comment: Comment) {
    self.comment = comment
  }

  // MARK: Internal

  let comment: Comment

  var body: some View {
    HStack {
      Button(action: {
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
              Illithid.shared.logger.errorMessage("Error upvoting \(self.comment.author) - \(self.comment.fullname): \(error)")
            }
          }
        }
      }, label: {
        Image(systemName: "arrow.up")
      })
        .foregroundColor(vote == .up ? .orange : .white)

      Button(action: {
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
              Illithid.shared.logger.errorMessage("Error downvoting \(self.comment.author) - \(self.comment.fullname): \(error)")
            }
          }
        }
      }, label: {
        Image(systemName: "arrow.down")
      })
        .foregroundColor(vote == .down ? .purple : .white)

      Button(action: {
        self.saved.toggle()
        if self.saved {
          self.comment.save { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error saving \(self.comment.author) - \(self.comment.fullname): \(error)")
            }
          }
        } else {
          self.comment.unsave { result in
            if case let Result.failure(error) = result {
              Illithid.shared.logger.errorMessage("Error unsaving \(self.comment.author) - \(self.comment.fullname): \(error)")
            }
          }
        }
      }, label: {
        Image(systemName: "bookmark.fill")
      })
        .foregroundColor(saved ? .green : .white)

      Button(action: {}, label: {
        Image(systemName: "flag.fill")
      })
        .buttonStyle(DangerButtonStyle())
        .help("Report comment")

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

  // MARK: Private

  @State private var vote: VoteDirection = .clear
  @State private var saved: Bool = false
}

// MARK: - CommentColorBar

struct CommentColorBar: View {
  // MARK: Lifecycle

  init(isCollapsed: Binding<Bool>, for comment: Comment) {
    depth = comment.depth ?? 0
    _isCollapsed = isCollapsed
  }

  init(for more: More) {
    depth = more.depth
    // A more view may not be collapsed
    _isCollapsed = .constant(false)
  }

  // MARK: Internal

  @Binding var isCollapsed: Bool

  var body: some View {
    if depth > 0 {
      RoundedRectangle(cornerRadius: 1.5, style: .continuous)
        .foregroundColor(foregroundColor)
        .frame(width: width)
        .onTapGesture {
          withAnimation {
            isCollapsed.toggle()
          }
        }
        .onHover { hovering in
          withAnimation {
            isHovered = hovering
          }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .shadow(color: isHovered ? .accentColor : .clear, radius: 8)
        .shadow(color: isHovered ? .accentColor : .clear, radius: 8)
    }
  }

  // MARK: Private

  @State private var isHovered: Bool = false
  private let depth: Int
  private let width: CGFloat = 3.0

  private var foregroundColor: Color {
    isHovered
      ? .accentColor
      : Color(hue: 1.0 / Double(depth), saturation: 1.0, brightness: 1.0)
  }
}

extension Text {
  func usernameStyle(color: Color) -> Text {
    fontWeight(.bold)
      .foregroundColor(color)
  }
}

// MARK: - CommentRowView_Previews

struct CommentRowView_Previews: PreviewProvider {
  static var previews: some View {
    let testCommentsPath = Bundle.main.path(forResource: "comments", ofType: "json")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: testCommentsPath))
    let decoder = JSONDecoder()
    let listing = try! decoder.decode(Listing.self, from: data)

    return CommentRowView(isCollapsed: .constant(false), comment: listing.comments.first!)
  }
}
