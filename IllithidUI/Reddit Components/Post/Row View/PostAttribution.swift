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

struct PostAttribution: View {
  // MARK: Lifecycle

  init(post: Post) {
    self.post = post
    _moderators = .init(initialValue: .shared)
  }

  // MARK: Internal

  let post: Post

  var body: some View {
    HStack(spacing: 8) {
      Text(verbatim: post.subredditNamePrefixed)
        .lineLimit(1)
        .onTapGesture {
          windowManager.showMainWindowTab(withId: post.subredditId, title: post.subredditNamePrefixed) {
            SubredditLoader(fullname: post.subredditId)
              .environmentObject(informationBarData)
          }
        }
      Text(Image(systemName: "circle.fill"))
        .font(.system(size: 4.0))
        .fontWeight(.light)
      (Text("post.attribution")
        + Text(verbatim: " ")
        + Text(verbatim: post.authorPrefixed).usernameStyle(color: authorColor))
        .lineLimit(1)
        .onTapGesture {
          windowManager.showMainWindowTab(withId: post.author, title: post.author) {
            AccountView(name: post.author)
              .environmentObject(informationBarData)
          }
        }
    }
  }

  // MARK: Private

  private let windowManager: WindowManager = .shared
  @ObservedObject private var moderators: ModeratorData
  @EnvironmentObject private var informationBarData: InformationBarData

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
