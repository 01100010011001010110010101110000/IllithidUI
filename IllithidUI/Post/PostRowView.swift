//
// PostRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
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
                  .resizable()
                  .frame(width: 16, height: 24)
                  .foregroundColor(.green)
                  .padding(.top, 2.0)
              }
              if post.locked {
                Image(systemName: "lock.circle.fill")
                  .resizable()
                  .frame(width: 24, height: 24)
                  .foregroundColor(.green)
                  .padding(.top, 2.0)
                  .help(Post.lockedDescription)
              }
              Spacer()
              PostFlairBar(post: self.post)
                .padding(.top, 2.0)
              Spacer()
            }
            Text(self.post.title)
              .font(.title)
              .multilineTextAlignment(.center)
//              .heightResizable()
              .padding([.leading, .trailing, .bottom])
          }

          if let crosspostParent = self.crosspostParent {
            GroupBox {
              VStack {
                PostFlairBar(post: crosspostParent)
                  .padding(.top, 2.0)
                Text(crosspostParent.title)
                  .font(.title)
                  .multilineTextAlignment(.center)
//                  .heightResizable()
                  .padding()

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

extension Post {
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
  }

  var body: some View {
    VStack {
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(Color(.darkGray))
        .overlay(Image(systemName: "arrow.up")
          .resizable()
          .foregroundColor(vote == .up ? .orange : .white)
          .frame(width: 24, height: 24), alignment: .center)
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
          .resizable()
          .foregroundColor(vote == .down ? .purple : .white)
          .frame(width: 24, height: 24), alignment: .center)
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
          .resizable()
          .foregroundColor(saved ? .green : .white)
          .frame(width: 24, height: 24), alignment: .center)
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
          .resizable()
          .foregroundColor(.white)
          .frame(width: 24, height: 24), alignment: .center)
        .frame(width: 32, height: 32)
      RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(.red)
        .overlay(Image(systemName: "flag")
          .resizable()
          .foregroundColor(.white)
          .frame(width: 24, height: 24), alignment: .center)
        .foregroundColor(.white)
        .frame(width: 32, height: 32)
      Spacer()
    }
    .padding(10)
    .onAppear {
      if let likeDirection = self.post.likes {
        self.vote = likeDirection ? .up : .down
      } else {
        self.vote = .clear
      }
      self.saved = self.post.saved
    }
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
            AccountView(accountData: .init(name: self.post.author))
              .environmentObject(self.informationBarData)
          }
        }
      Spacer()
      HStack {
        Group {
          Image(systemName: "arrow.up")
            .resizable()
            .frame(width: 20, height: 20)
          Text("\(post.ups.postAbbreviation())")
        }
        .foregroundColor(.orange)

        Group {
          Image(systemName: "text.bubble")
            .resizable()
            .frame(width: 24, height: 20)
          Text("\(post.numComments.postAbbreviation())")
        }
        .foregroundColor(.blue)

        Group {
          Image(systemName: "clock")
            .resizable()
            .frame(width: 20, height: 20)
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
    .font(.caption)
  }
}

// MARK: Post Flair

struct PostFlairBar: View {
  let post: Post

  var body: some View {
    HStack {
      if post.over18 {
        Text("NSFW")
          .flairTag(rectangleColor: .red)
      }

      if post.authorFlairType == .text {
        post.authorFlairText.map { flair in
          Group {
            if !flair.isEmpty {
              Text(flair)
                .flairTag(rectangleColor: .blue)
            } else {
              EmptyView()
            }
          }
        }
      } else if post.authorFlairType == .richtext {
        HStack {
          ForEach(post.authorFlairRichtext!.indices) { idx in
            self.renderRichtext(self.post.authorFlairRichtext![idx])
          }
        }
        .flairTag(rectangleColor: .blue)
      }

      if post.linkFlairType == .text {
        post.linkFlairText.map { flair in
          Group {
            if !flair.isEmpty {
              Text(flair)
                .flairTag(rectangleColor: .blue)
            } else {
              EmptyView()
            }
          }
        }
      } else if post.linkFlairType == .richtext {
        HStack {
          ForEach(post.linkFlairRichtext!.indices) { idx in
            self.renderRichtext(self.post.linkFlairRichtext![idx])
          }
        }
        .flairTag(rectangleColor: .blue)
      }
    }
  }

  private func renderRichtext(_ text: FlairRichtext) -> AnyView {
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
  func flairTag(rectangleColor: Color = .white) -> some View {
    padding(4.0)
      .background(RoundedRectangle(cornerRadius: 4.0)
        .foregroundColor(rectangleColor)
      )
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
