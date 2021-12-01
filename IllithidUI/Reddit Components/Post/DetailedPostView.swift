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
import SDWebImageSwiftUI

// MARK: - DetailedPostView

struct DetailedPostView: View {
  // MARK: Lifecycle

  init(post: Post, vote: Binding<VoteDirection>? = nil) {
    self.post = post
    if post.crosspostParentList != nil, !post.crosspostParentList!.isEmpty {
      crosspostParent = post.crosspostParentList?.first!
    } else {
      crosspostParent = nil
    }

    if let vote = vote { _vote = vote }
    else { _vote = .constant(VoteDirection(from: post)) }
  }

  // MARK: Internal

  let post: Post
  let crosspostParent: Post?

  @Binding var vote: VoteDirection

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      VStack(alignment: .leading) {
        if crosspostParent != nil {
          Text("Crossposted by \(post.author) \(post.relativePostTime) ago")
            .font(.caption)
        }
        HStack {
          Group {
            if post.stickied {
              Image(systemName: "pin.fill")
                .help("post.pinned")
            }
            if post.locked {
              Image(systemName: "lock.fill")
                .help("post.locked")
            }
          }
          .font(.title2)
          .foregroundColor(.green)

          PostRowView.TitleView(post: post)
        }
      }

      if let crosspostParent = crosspostParent {
        GroupBox {
          VStack(alignment: .leading, spacing: 10) {
            PostRowView.TitleView(post: crosspostParent)

            PostContent(post: crosspostParent)

            PostRowView.PostMetadataBar(post: crosspostParent, vote: $vote)
          }
        }
        .padding(.horizontal, 4)
        .onTapGesture(count: 2) {
          showComments(for: crosspostParent)
        }
      } else {
        PostContent(post: post)
      }

      PostRowView.PostMetadataBar(post: post, vote: $vote)
    }
  }

  func showComments(for post: Post) {
    WindowManager.shared.showMainWindowTab(withId: post.name, title: post.title) {
      CommentsView(post: post)
    }
  }
}

// MARK: - FlairRichTextView

struct FlairRichTextView: View {
  // MARK: Internal

  let richText: [FlairRichtext]
  let backgroundColor: Color
  let textColor: Color

  var body: some View {
    HStack {
      ForEach(richText.indices, id: \.self) { idx in
        Self.renderRichText(richText[idx])
      }
    }
    .flairTag(rectangleColor: .accentColor)
  }

  // MARK: Private

  @ViewBuilder
  private static func renderRichText(_ text: FlairRichtext) -> some View {
    switch text.type {
    case .emoji:
      WebImage(url: text.emojiUrl)
        .resizable()
        .frame(width: 24, height: 24)
        .help(text.emojiShortcode ?? "")
    case .text:
      if let flairText = text.text {
        Text(flairText)
          .fixedSize(horizontal: true, vertical: false)
      } else {
        EmptyView()
      }
    }
  }
}

extension View {
  func flairTag(rectangleColor: Color = .accentColor) -> some View {
    padding(.horizontal, 8)
      .background(
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(rectangleColor)
      )
  }
}

extension Post {
  var authorFlairTextSwiftUiColor: Color {
    switch authorFlairTextColor {
    case .light:
      return .white
    case .dark:
      return .black
    default:
      return .white
    }
  }

  var linkFlairTextSwiftUiColor: Color {
    switch linkFlairTextColor {
    case .light:
      return .white
    case .dark:
      return .black
    default:
      return .white
    }
  }
}
