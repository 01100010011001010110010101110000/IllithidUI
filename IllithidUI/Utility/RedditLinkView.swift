//
// RedditLinkView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/10/2020

import SwiftUI

import Illithid

struct RedditLinkView: View {
  let link: URL

  private let icon = NSImage(named: .redditSquare)!
  private let windowManager: WindowManager = .shared

  var body: some View {
    VStack {
      LinkBar(icon: icon, link: link)
        .frame(width: 512)
        .background(Color(.controlBackgroundColor))
        .modifier(RoundedBorder(style: Color(.darkGray),
                                cornerRadius: 8.0, width: 2.0))
        .onTapGesture {
          self.openRedditLink(link: self.link)
        }
    }
  }

  private func openRedditLink(link: URL) {
    let path = link.path
    let fullRange = NSRange(path.startIndex ..< path.endIndex, in: path)

    let multiRegex = try! NSRegularExpression(pattern: #"\/user\/(?<user>\w+)\/m\/(?<name>\w+)(\/)?$"#, options: [])
    let subredditRegex = try! NSRegularExpression(pattern: #"\/r\/(?<subreddit>\w+)(\/)?$"#, options: [])
    let accountRegex = try! NSRegularExpression(pattern: #"\/user\/(?<user>\w+)(\/)?$"#, options: [])
    let postRegex = try! NSRegularExpression(pattern: #"\/r\/(?<subreddit>\w+)\/comments\/(?<postId36>\w+)(\/\w+(\/(?<commentId36>\w+))?)?(\/)?$"#, options: [])

    if let match = multiRegex.firstMatch(in: path, options: [], range: fullRange),
      let userRange = Range(match.range(withName: "user"), in: path),
      let multiNameRange = Range(match.range(withName: "name"), in: path) {
        let user = String(path[userRange])
        let multiName = String(path[multiNameRange])
        Multireddit.fetch(user: user, name: multiName) { result in
          switch result {
          case let .success(multi):
            self.windowManager.showWindow(withId: multi.id, title: multi.displayName) {
              PostListView(postContainer: multi)
            }
          case let .failure(error):
            Illithid.shared.logger.errorMessage("Unable to fetch multireddit: \(error)")
          }
        }
    } else if let match = subredditRegex.firstMatch(in: path, options: [], range: fullRange),
      let subredditRange = Range(match.range(withName: "subreddit"), in: path) {
      let subreddit = String(path[subredditRange])
      Subreddit.fetch(displayName: subreddit) { result in
        switch result {
        case let .success(subreddit):
          self.windowManager.showWindow(withId: subreddit.id, title: subreddit.displayName) {
            PostListView(postContainer: subreddit)
          }
        case let .failure(error):
          Illithid.shared.logger.errorMessage("Unable to fetch subreddit: \(error)")
        }
      }
    } else if let match = accountRegex.firstMatch(in: path, options: [], range: fullRange),
      let userRange = Range(match.range(withName: "user"), in: path) {
      let username = String(path[userRange])
      Account.fetch(username: username) { result in
        switch result {
        case let .success(account):
          self.windowManager.showWindow(withId: account.id, title: account.name) {
            AccountView(accountData: .init(account: account))
          }
        case let .failure(error):
          Illithid.shared.logger.errorMessage("Unable to fetch account: \(error)")
        }
      }
    } else if let match = postRegex.firstMatch(in: path, options: [], range: fullRange),
      let postId36Range = Range(match.range(withName: "postId36"), in: path) {
      let postId36 = String(path[postId36Range])
      let focusedCommentRange = Range(match.range(withName: "commentId36"), in: path)
      let focusedCommentId = focusedCommentRange != nil ? String(path[focusedCommentRange!]) : nil
      Post.fetch(name: "t3_\(postId36)") { result in
        switch result {
        case let .success(post):
          self.windowManager.showWindow(withId: post.fullname, title: post.title) {
            CommentsView(post: post, focusOn: focusedCommentId)
          }
        case let .failure(error):
          Illithid.shared.logger.errorMessage("Unable to fetch post: \(error)")
        }
      }
    }
  }
}

// struct RedditLinkView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedditLinkView()
//    }
//}
