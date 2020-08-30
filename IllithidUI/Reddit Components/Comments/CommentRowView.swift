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

struct CommentRowView: View {
  @State private var textSize: CGRect = .zero
  @Binding var isCollapsed: Bool

  let comment: Comment

  var body: some View {
    VStack {
      HStack {
        if (comment.depth ?? 0) > 0 {
          CommentColorBar(depth: comment.depth!)
        }

        if comment.isRemoved {
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
        } else if comment.isDeleted {
          VStack {
            AuthorBar(isCollapsed: $isCollapsed, comment: comment)
            if !isCollapsed {
              Text("Deleted by author")
            }
          }
        } else {
          VStack(alignment: .leading) {
            AuthorBar(isCollapsed: $isCollapsed, comment: comment)

            if !isCollapsed {
              Text(comment.body)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding()

              CommentActionBar(comment: comment)
                .padding(.bottom, 5)
            }
          }
        }
      }
      Divider()
    }
    .padding(.leading, 12 * CGFloat(integerLiteral: comment.depth ?? 0))
  }
}

private struct AuthorBar: View {
  @ObservedObject private var moderators: ModeratorData = .shared
  @Binding var isCollapsed: Bool

  let comment: Comment

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

  var body: some View {
    HStack {
      Text(comment.author)
        .usernameStyle(color: authorColor)
      Text(comment.scoreHidden ? "\u{2205}" : String(comment.ups.postAbbreviation(1)))
        .foregroundColor(.orange)
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

struct MoreCommentsRowView: View {
  let more: More

  var body: some View {
    HStack {
      if more.depth > 0 {
        CommentColorBar(depth: more.depth)
      }

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
                Illithid.shared.logger.errorMessage("Error upvoting \(self.comment.author) - \(self.comment.fullname): \(error)")
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
                Illithid.shared.logger.errorMessage("Error downvoting \(self.comment.author) - \(self.comment.fullname): \(error)")
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
        }
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

struct CommentColorBar: View {
  let depth: Int
  let width: CGFloat = 3.0

  var body: some View {
    RoundedRectangle(cornerRadius: 1.5)
      .foregroundColor(Color(hue: 1.0 / Double(depth), saturation: 1.0, brightness: 1.0))
      .frame(width: width)
  }
}

extension Text {
  func usernameStyle(color: Color) -> Text {
    fontWeight(.bold)
      .foregroundColor(color)
  }
}

struct CommentRowView_Previews: PreviewProvider {
  static var previews: some View {
    let testCommentsPath = Bundle.main.path(forResource: "comments", ofType: "json")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: testCommentsPath))
    let decoder = JSONDecoder()
    let listing = try! decoder.decode(Listing.self, from: data)

    return CommentRowView(isCollapsed: .constant(false), comment: listing.comments.first!)
  }
}
