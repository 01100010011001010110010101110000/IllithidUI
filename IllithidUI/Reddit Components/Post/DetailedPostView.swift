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
  }
}
