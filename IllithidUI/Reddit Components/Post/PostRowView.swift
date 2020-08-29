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
import SDWebImageSwiftUI

// MARK: Main row view

struct PostRowView: View {
  let post: Post
  let crosspostParent: Post?

  let windowManager: WindowManager = .shared

  init(post: Post) {
    self.post = post

    if post.crosspostParentList != nil, !post.crosspostParentList!.isEmpty {
      crosspostParent = post.crosspostParentList?.first!
    } else {
      crosspostParent = nil
    }
  }

  var body: some View {
    GroupBox {
      HStack {
        PostActionBar(post: post)
        Divider()
        VStack {
          VStack {
            if crosspostParent != nil {
              Text("Crossposted by \(post.author) \(post.relativePostTime) ago")
                .font(.caption)
            }
            HStack {
              if post.stickied {
                Image(systemName: "pin.circle.fill")
                  .font(.title)
                  .foregroundColor(.green)
                  .help(Post.pinnedDescription)
              }
              if post.locked {
                Image(systemName: "lock.circle.fill")
                  .font(.title)
                  .foregroundColor(.green)
                  .help(Post.lockedDescription)
              }
              Spacer()
            }
            TitleView(post: post)
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
    }
    .onTapGesture(count: 2) {
      showComments(for: post)
    }
    .contextMenu {
      Button(action: {
        showComments(for: post)
      }, label: {
        Text("Show comments…")
      })
      Divider()
      Button(action: {
        openLink(post.postUrl)
      }, label: {
        Text("Open post…")
      })
      Button(action: {
        openLink(post.contentUrl)
      }, label: {
        Text("Open post content…")
      })
      Divider()
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(post.postUrl.absoluteString, forType: .string)
      }, label: {
        Text("Copy post URL")
      })
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(post.contentUrl.absoluteString, forType: .string)
      }, label: {
        Text("Copy content URL")
      })
      Divider()
      #if DEBUG
        Button(action: {
          showDebugWindow(for: post)
        }) {
          Text("Show debug panel…")
        }
      #endif
    }
  }

  func showComments(for post: Post) {
    windowManager.showMainWindowTab(withId: post.name, title: post.title) {
      CommentsView(post: post)
    }
  }

  func showDebugWindow(for post: Post) {
    windowManager.showMainWindowTab(withId: "\(post.name)_debug", title: "\(post.title) - Debug View") {
      PostDebugView(post: post)
    }
  }
}

private struct TitleView: View {
  let post: Post

  var body: some View {
    HStack {
      if let richtext = post.linkFlairRichtext, !richtext.isEmpty {
        FlairRichtextView(richtext: richtext,
                          backgroundColor: post.linkFlairBackgroundSwiftUiColor ?? .accentColor,
                          textColor: post.authorFlairTextSwiftUiColor)
      } else if let text = post.linkFlairText, !text.isEmpty {
        Text(text)
          .foregroundColor(post.linkFlairTextSwiftUiColor)
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
    .padding([.leading, .trailing, .bottom])
  }
}

extension Post {
  static let pinnedDescription: String = "This post has been pinned by a moderator"
  static let lockedDescription: String = "This post has been locked. New comments are disabled"
}

// MARK: Post meta views

// TODO: Sync saved and voted state with model
struct PostActionBar: View {
  @State private var vote: VoteDirection = .clear
  @State private var saved: Bool = false
  let post: Post

  init(post: Post) {
    self.post = post

    // Likes is actually ternary, with nil implying no vote
    if let likeDirection = post.likes {
      _vote = .init(initialValue: likeDirection ? .up : .down)
    } else {
      _vote = .init(initialValue: .clear)
    }
    _saved = .init(initialValue: post.saved)
  }

  var body: some View {
    VStack {
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(Color(.darkGray))
        .overlay(Image(systemName: "arrow.up")
          .foregroundColor(vote == .up ? .orange : .white))
        .onTapGesture {
          if vote == .up {
            vote = .clear
            post.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(post.title) - \(post.name): \(error)")
              }
            }
          } else {
            vote = .up
            post.upvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error upvoting \(post.title) - \(post.name): \(error)")
              }
            }
          }
        }
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(Color(.darkGray))
        .overlay(Image(systemName: "arrow.down")
          .foregroundColor(vote == .down ? .purple : .white))
        .onTapGesture {
          if vote == .down {
            vote = .clear
            post.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(post.title) - \(post.name): \(error)")
              }
            }
          } else {
            vote = .down
            post.downvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error downvoting \(post.title) - \(post.name): \(error)")
              }
            }
          }
        }
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(Color(.darkGray))
        .overlay(Image(systemName: "bookmark")
          .foregroundColor(saved ? .green : .white))
        .onTapGesture {
          saved.toggle()
          if saved {
            post.save { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error saving \(post.title) - \(post.name): \(error)")
              }
            }
          } else {
            post.unsave { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error unsaving \(post.title) - \(post.name): \(error)")
              }
            }
          }
        }
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(.red)
        .overlay(Image(systemName: "eye.slash")
          .foregroundColor(.white))
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(.red)
        .overlay(Image(systemName: "flag")
          .foregroundColor(.white))
        .foregroundColor(.white)
        .frame(width: 32, height: 32)
      Spacer()
    }
    .font(.title)
    .padding(10)
  }
}

struct PostMetadataBar: View {
  @EnvironmentObject var informationBarData: InformationBarData

  @ObservedObject private var moderators: ModeratorData = .shared

  let post: Post
  private let windowManager: WindowManager = .shared

  private var authorColor: Color {
    if post.isAdminPost {
      return .red
    } else if moderators.isModerator(username: post.author, ofSubreddit: post.subreddit) {
      return .green
    } else {
      return .white
    }
  }

  init(post: Post) {
    self.post = post
  }

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
      if let richtext = post.authorFlairRichtext, !richtext.isEmpty {
        FlairRichtextView(richtext: richtext,
                          backgroundColor: post.authorFlairBackgroundSwiftUiColor ?? .accentColor,
                          textColor: post.authorFlairTextSwiftUiColor)
      } else if let text = post.authorFlairText, !text.isEmpty {
        Text(text)
          .foregroundColor(post.authorFlairTextSwiftUiColor)
          .flairTag(rectangleColor: post.authorFlairBackgroundSwiftUiColor ?? .accentColor)
      }
      Spacer()
      HStack {
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
      Spacer()
      Text(post.subredditNamePrefixed)
        .onTapGesture {
          windowManager.showMainWindowTab(withId: post.subredditId, title: post.subredditNamePrefixed) {
            SubredditLoader(fullname: post.subredditId)
              .environmentObject(informationBarData)
          }
        }
    }
    .padding(10)
    .font(.body)
  }
}

// MARK: Post Flair

struct FlairRichtextView: View {
  let richtext: [FlairRichtext]
  let backgroundColor: Color
  let textColor: Color

  var body: some View {
    HStack {
      ForEach(richtext.indices) { idx in
        Self.renderRichtext(richtext[idx])
      }
    }
    .flairTag(rectangleColor: .accentColor)
  }

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

// MARK: Static Previews

struct PostRowView_Previews: PreviewProvider {
  static var previews: some View {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970

    let singlePostURL = Bundle.main.url(forResource: "single_post", withExtension: "json")!
    let data = try! Data(contentsOf: singlePostURL)
    let post = try! decoder.decode(Post.self, from: data)

    return PostRowView(post: post)
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
