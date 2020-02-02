//
// PostRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct PostRowView: View {
  let reddit: Illithid = .shared
  let post: Post
  let crosspostParent: Post?

  let commentsManager: WindowManager<CommentsView>

  init(post: Post, commentsManager: WindowManager<CommentsView> = .init()) {
    self.post = post
    self.commentsManager = commentsManager

    if post.crosspostParentList != nil, !post.crosspostParentList!.isEmpty {
      crosspostParent = post.crosspostParentList?.first!
    } else {
      crosspostParent = nil
    }
  }

  var body: some View {
    GroupBox {
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
    .onTapGesture(count: 2) {
      self.showComments(for: self.post)
    }
  }

  func showComments(for post: Post) {
    commentsManager.showWindow(for: CommentsView(post: post), title: post.title)
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
      Spacer()
      HStack {
        Text("\(post.ups.postAbbreviation())")
          .foregroundColor(.orange)
        Text("\(post.downs.postAbbreviation())")
          .foregroundColor(.purple)
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

#if DEBUG
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
#endif
