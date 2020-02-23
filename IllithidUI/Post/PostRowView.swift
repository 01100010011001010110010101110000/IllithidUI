//
// PostRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

// MARK: Main row view

struct PostRowView: View {
  @EnvironmentObject var subredditManager: WindowManager<PostListView<Subreddit>>
  let reddit: Illithid = .shared
  let post: Post
  let crosspostParent: Post?

  let commentsManager: WindowManager<CommentsView>
  let debugManager: WindowManager<PostDebugView>

  init(post: Post, commentsManager: WindowManager<CommentsView> = .init(), debugManager: WindowManager<PostDebugView> = .init()) {
    self.post = post
    self.commentsManager = commentsManager
    self.debugManager = debugManager

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
            Text(self.post.title)
              .font(.title)
              .multilineTextAlignment(.center)
              .tooltip(post.title)
              .padding([.leading, .trailing, .bottom])
          }

          if crosspostParent != nil {
            GroupBox {
              VStack {
                Text(crosspostParent!.title)
                  .font(.title)
                  .multilineTextAlignment(.center)
                  .tooltip(crosspostParent!.title)
                  .padding()

                PostContent(post: crosspostParent!)

                PostMetadataBar(post: crosspostParent!)
              }
            }
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
      }) {
        Text("Show comments…")
      }
      Divider()
      Button(action: {
        NSWorkspace.shared.open(self.post.postUrl)
      }) {
        Text("Open post in browser…")
      }
      Button(action: {
        NSWorkspace.shared.open(self.post.contentUrl)
      }) {
        Text("Open content in browser…")
      }
      Divider()
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.post.postUrl.absoluteString, forType: .string)
      }) {
        Text("Copy post URL")
      }
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.post.contentUrl.absoluteString, forType: .string)
      }) {
        Text("Copy content URL")
      }
      Divider()
      Button(action: {
        self.showDebugWindow(for: self.post)
      }) {
        Text("Show debug panel…")
      }
    }
  }

  func showComments(for post: Post) {
    commentsManager.showWindow(for: CommentsView(post: post), title: post.title)
  }

  func showDebugWindow(for post: Post) {
    debugManager.showWindow(for: PostDebugView(post: post), title: "\(post.title) - Debug View")
  }
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
        .foregroundColor(vote == .up ? .orange : Color(.darkGray))
        .overlay(Text("Up"), alignment: .center)
        .foregroundColor(.white)
        .onTapGesture {
          if self.vote == .up {
            self.vote = .clear
            self.post.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.fullname): \(error)")
              }
            }
          } else {
            self.vote = .up
            self.post.upvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.fullname): \(error)")
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
            self.post.clearVote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.fullname): \(error)")
              }
            }
          } else {
            self.vote = .down
            self.post.downvote { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.fullname): \(error)")
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
            self.post.save { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.fullname): \(error)")
              }
            }
          } else {
            self.post.unsave { result in
              if case let Result.failure(error) = result {
                Illithid.shared.logger.errorMessage("Error clearing vote on \(self.post.title) - \(self.post.fullname): \(error)")
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
  @State var authorPopover = false
  let post: Post

  var body: some View {
    HStack {
      Button(post.author) {
        self.authorPopover.toggle()
      }
      .popover(isPresented: $authorPopover) {
        AccountView(accountData: .init(name: self.post.author))
      }
      Text("\(post.relativePostTime) ago")
      Spacer()
      HStack {
        Text("\(post.ups.postAbbreviation())")
          .foregroundColor(.orange)
        Text("\(post.numComments.postAbbreviation())")
          .foregroundColor(.blue)
      }
      Spacer()
      Text(post.subredditNamePrefixed)
    }
    .padding(10)
    .font(.caption)
  }
}

// MARK: Static Previews

struct PostRowView_Previews: PreviewProvider {
  static var previews: some View {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .secondsSince1970

    let singlePostURL = Bundle.main.url(forResource: "single_post", withExtension: "json")!
    let data = try! Data(contentsOf: singlePostURL)
    let post = try! decoder.decode(Post.self, from: data)

    return PostRowView(post: post)
  }
}
