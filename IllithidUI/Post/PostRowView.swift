//
// PostRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/1/20
//

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
              Text("Crossposted by \(self.post.author) \(self.post.relativePostTime) ago")
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

          if let crosspostParent = self.crosspostParent {
            GroupBox {
              VStack {
                TitleView(post: crosspostParent)

                PostContent(post: crosspostParent)

                PostMetadataBar(post: crosspostParent)
              }
            }
            .padding([.leading, .trailing], 4.0)
            .onTapGesture(count: 2) {
              self.showComments(for: self.crosspostParent!)
            }
          } else {
            PostContent(post: post)
          }

          PostMetadataBar(post: post)
        }
      }
    }
    .onTapGesture(count: 2) {
      self.showComments(for: self.post)
    }
    .contextMenu {
      Button(action: {
        self.showComments(for: self.post)
      }, label: {
        Text("Show comments…")
      })
      Divider()
      Button(action: {
        openLink(self.post.postUrl)
      }, label: {
        Text("Open post…")
      })
      Button(action: {
        openLink(self.post.contentUrl)
      }, label: {
        Text("Open post content…")
      })
      Divider()
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.post.postUrl.absoluteString, forType: .string)
      }, label: {
        Text("Copy post URL")
      })
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.post.contentUrl.absoluteString, forType: .string)
      }, label: {
        Text("Copy content URL")
      })
      Divider()
      #if DEBUG
        Button(action: {
          self.showDebugWindow(for: self.post)
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
        FlairRichtextView(richtext: richtext)
      } else if let text = post.linkFlairText, !text.isEmpty {
        Text(text)
          .flairTag()
      }

      Text(self.post.title)
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
    if let likeDirection = self.post.likes {
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
          if self.vote == .up {
            self.vote = .clear
            self.post.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.name): \(error)")
              }
            }
          } else {
            self.vote = .up
            self.post.upvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error upvoting \(self.post.title) - \(self.post.name): \(error)")
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
          if self.vote == .down {
            self.vote = .clear
            self.post.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.name): \(error)")
              }
            }
          } else {
            self.vote = .down
            self.post.downvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error downvoting \(self.post.title) - \(self.post.name): \(error)")
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
          self.saved.toggle()
          if self.saved {
            self.post.save { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error saving \(self.post.title) - \(self.post.name): \(error)")
              }
            }
          } else {
            self.post.unsave { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error unsaving \(self.post.title) - \(self.post.name): \(error)")
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
          self.windowManager.showMainWindowTab(withId: self.post.author, title: self.post.author) {
            AccountView(name: self.post.author)
              .environmentObject(self.informationBarData)
          }
        }
      if let richtext = post.authorFlairRichtext, !richtext.isEmpty {
        FlairRichtextView(richtext: richtext)
      } else if let text = post.authorFlairText, !text.isEmpty {
        Text(text)
          .flairTag()
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
          self.windowManager.showMainWindowTab(withId: self.post.subredditId, title: self.post.subredditNamePrefixed) {
            SubredditLoader(fullname: self.post.subredditId)
              .environmentObject(self.informationBarData)
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

  var body: some View {
    HStack {
      ForEach(richtext.indices) { idx in
        Self.renderRichtext(richtext[idx])
      }
    }
    .flairTag(rectangleColor: .accentColor)
  }

  private static func renderRichtext(_ text: FlairRichtext) -> AnyView {
    switch text.type {
    case .emoji:
      return WebImage(url: text.emojiUrl)
        .resizable()
        .frame(width: 24, height: 24)
        .help(text.emojiShortcode ?? "")
        .eraseToAnyView()
    case .text:
      if let flairText = text.text {
        return Text(flairText)
          .fixedSize(horizontal: true, vertical: false)
          .eraseToAnyView()
      } else {
        return EmptyView()
          .eraseToAnyView()
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
