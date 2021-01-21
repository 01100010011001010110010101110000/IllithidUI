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

  init(post: Post) {
    self.post = post
    if post.crosspostParentList != nil, !post.crosspostParentList!.isEmpty {
      crosspostParent = post.crosspostParentList?.first!
    } else {
      crosspostParent = nil
    }
  }

  // MARK: Internal

  let post: Post
  let crosspostParent: Post?

  var body: some View {
    VStack {
      VStack {
        if crosspostParent != nil {
          Text("Crossposted by \(post.author) \(post.relativePostTime) ago")
            .font(.caption)
        }
        HStack(alignment: .center) {
          HStack(alignment: .center) {
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
          .padding(.leading, 10)
          Spacer()
          TitleView(post: post)
          Spacer()
        }
        .padding(.top)
      }

      if let crosspostParent = crosspostParent {
        GroupBox {
          VStack {
            TitleView(post: crosspostParent)

            PostContent(post: crosspostParent)

            PostMetadataBar(post: crosspostParent)
          }
        }
        .padding([.leading, .trailing], 4.0)
        .onTapGesture(count: 2) {
          showComments(for: crosspostParent)
        }
      } else {
        PostContent(post: post)
      }

      PostMetadataBar(post: post)
    }
  }

  func showComments(for post: Post) {
    WindowManager.shared.showMainWindowTab(withId: post.name, title: post.title) {
      CommentsView(post: post)
    }
  }
}

// MARK: - TitleView

private struct TitleView: View {
  // MARK: Internal

  let post: Post

  var body: some View {
    HStack {
      if let richtext = post.linkFlairRichtext, !richtext.isEmpty {
        FlairRichtextView(richtext: richtext,
                          backgroundColor: post.linkFlairBackgroundSwiftUiColor ?? .accentColor,
                          textColor: flairTextColor)
      } else if let text = post.linkFlairText, !text.isEmpty {
        Text(text)
          .foregroundColor(flairTextColor)
          .flairTag(rectangleColor: post.linkFlairBackgroundSwiftUiColor ?? .accentColor)
      }

      Text(post.title)
        .font(.title)
        .heightResizable()
        .multilineTextAlignment(.center)

      if post.over18 {
        Text("NSFW")
          .flairTag(rectangleColor: .red)
      }
    }
  }

  // MARK: Private

  private var flairTextColor: Color {
    post.linkFlairBackgroundSwiftUiColor == nil
      ? Color(.textColor)
      : post.authorFlairTextSwiftUiColor
  }
}

// MARK: - PostMetadataBar

private struct PostMetadataBar: View {
  // MARK: Lifecycle

  init(post: Post) {
    self.post = post
  }

  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData

  let post: Post

  var body: some View {
    HStack {
      (Text("by ") +
        Text("\(post.author)")
        .usernameStyle(color: authorColor))
        .onTapGesture {
          windowManager.showMainWindowTab(withId: post.author, title: post.author) {
            AccountView(name: post.author)
              .environmentObject(informationBarData)
          }
        }
        .fixedSize()
      if let richtext = post.authorFlairRichtext, !richtext.isEmpty {
        FlairRichtextView(richtext: richtext,
                          backgroundColor: post.authorFlairBackgroundSwiftUiColor ?? .accentColor,
                          textColor: authorFlairTextColor)
      } else if let text = post.authorFlairText, !text.isEmpty {
        Text(text)
          .foregroundColor(authorFlairTextColor)
          .flairTag(rectangleColor: post.authorFlairBackgroundSwiftUiColor ?? .accentColor)
      }
      Spacer()
      HStack {
        Group {
          Group {
            Image(systemName: "arrow.up")
            Text("\(post.ups.postAbbreviation())")
          }
          .foregroundColor(.orange)

          Group {
            Image(systemName: "text.bubble")
            Text("\(post.numComments.postAbbreviation())")
          }
          .foregroundColor(.blue)

          Group {
            Image(systemName: "clock")
            Text("\(post.relativePostTime) ago")
              .help(post.absolutePostTime)
          }
        }
        .fixedSize()
      }
      Spacer()
      Text(post.subredditNamePrefixed)
        .onTapGesture {
          windowManager.showMainWindowTab(withId: post.subredditId, title: post.subredditNamePrefixed) {
            SubredditLoader(fullname: post.subredditId)
              .environmentObject(informationBarData)
          }
        }
        .fixedSize()
    }
    .padding(10)
    .font(.body)
  }

  // MARK: Private

  @ObservedObject private var moderators: ModeratorData = .shared

  private let windowManager: WindowManager = .shared

  private var authorFlairTextColor: Color {
    post.authorFlairBackgroundSwiftUiColor == nil
      ? Color(.textColor)
      : post.authorFlairTextSwiftUiColor
  }

  private var authorColor: Color {
    if post.isAdminPost {
      return .red
    } else if moderators.isModerator(username: post.author, ofSubreddit: post.subreddit) {
      return .green
    } else {
      return .white
    }
  }
}

// MARK: - FlairRichtextView

private struct FlairRichtextView: View {
  // MARK: Internal

  let richtext: [FlairRichtext]
  let backgroundColor: Color
  let textColor: Color

  var body: some View {
    HStack {
      ForEach(richtext.indices, id: \.self) { idx in
        Self.renderRichtext(richtext[idx])
      }
    }
    .flairTag(rectangleColor: .accentColor)
  }

  // MARK: Private

  @ViewBuilder
  private static func renderRichtext(_ text: FlairRichtext) -> some View {
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
    padding(4.0)
      .background(rectangleColor)
      .clipShape(RoundedRectangle(cornerRadius: 4.0))
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
