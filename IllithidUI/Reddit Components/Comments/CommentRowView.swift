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

import Alamofire
import Illithid

// MARK: - CommentRowView

struct CommentRowView: View {
  // MARK: Lifecycle

  init(isCollapsed: Binding<Bool>, comment: Comment, scrollProxy: ScrollViewProxy? = nil) {
    _model = .init(wrappedValue: .init(comment))
    _isCollapsed = isCollapsed
    self.comment = comment
    self.scrollProxy = scrollProxy
  }

  // MARK: Internal

  @Binding var isCollapsed: Bool

  let comment: Comment
  let scrollProxy: ScrollViewProxy?

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
              Markdown(mdString: comment.body)
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
    .sheet(isPresented: $presentReplyForm) {
      NewCommentForm(replyTo: comment)
    }
    .padding(.leading, 12 * CGFloat(integerLiteral: comment.depth ?? 0))
    .environmentObject(model)
    .contextMenu {
      Button("comments.reply") {
        withAnimation {
          presentReplyForm = true
        }
      }
      Divider()

      AsyncButton("comments.upvote") { try? await model.upvote() }
      AsyncButton("comments.downvote") { try? await model.downvote() }

      Divider()

      AsyncButton(model.saved ? "comments.unsave" : "comments.save") {
        try? await model.toggleSaved()
      }

      Divider()

      Button(isCollapsed ? "comments.expand" : "comments.collapse") { toggleCollapsed() }

      if let depth = comment.depth ?? 0, depth != 0 {
        Button(action: {
          withAnimation {
            if let parentId36 = comment.parentId.components(separatedBy: "_").last {
              scrollProxy?.scrollTo(parentId36, anchor: .top)
            }
          }
        }, label: {
          Label("comments.scroll.parent.comment", systemImage: "ellipsis.bubble")
        })
      }
    }
  }

  // MARK: Private

  @State private var presentReplyForm: Bool = false

  @StateObject private var model: CommonActionModel<Comment>

  private func toggleCollapsed() {
    withAnimation {
      isCollapsed.toggle()
    }
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
      Text(comment.scoreHidden ? "-" : (comment.ups + model.vote.rawValue).postAbbreviation(1))
        .foregroundColor(.orange)
      Spacer()
      Text("\(comment.relativeCommentTime) ago")
    }
  }

  // MARK: Private

  @ObservedObject private var moderators: ModeratorData = .shared
  @EnvironmentObject private var model: CommonActionModel<Comment>

  private var authorColor: Color? {
    if comment.isAdminComment {
      return .red
    } else if moderators.isModerator(username: comment.author, ofSubreddit: comment.subreddit) {
      return .green
    } else if comment.isSubmitter {
      return .blue
    } else {
      return nil
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

private struct CommentActionBar: View {
  // MARK: Lifecycle

  init(comment: Comment) {
    self.comment = comment
  }

  // MARK: Internal

  let comment: Comment

  var body: some View {
    HStack {
      IllithidButton(action: {
        Task {
          try? await model.upvote()
        }
      }, label: {
        Image(systemName: "arrow.up")
      })
      .foregroundColor(model.vote == .up ? .orange : .white)

      IllithidButton(action: {
        Task {
          try? await model.downvote()
        }
      }, label: {
        Image(systemName: "arrow.down")
      })
      .foregroundColor(model.vote == .down ? .purple : .white)

      IllithidButton(action: {
        Task {
          try? await model.toggleSaved()
        }
      }, label: {
        Image(systemName: "bookmark.fill")
      })
      .foregroundColor(model.saved ? .green : .white)

      // TODO: Support button styling via environment in IllithidButton
      IllithidButton(action: {}, label: {
        Image(systemName: "flag.fill")
      })
      .buttonStyle(DangerButtonStyle())
      .help("comments.report")

      Spacer()
    }
    .padding(10)
  }

  // MARK: Private

  @EnvironmentObject private var model: CommonActionModel<Comment>
}

// MARK: - CommentColorBar

private struct CommentColorBar: View {
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

  // MARK: Private

  @State private var isHovered: Bool = false
  private let depth: Int
  private let width: CGFloat = 3.0

  private var foregroundColor: Color {
    isHovered
      ? .accentColor
      : Color(hue: 1.0 / Double(depth + 1), saturation: 1.0, brightness: 1.0)
  }
}

extension Text {
  func usernameStyle(color: Color?) -> Text {
    foregroundColor(color)
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
