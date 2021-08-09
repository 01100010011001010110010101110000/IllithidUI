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

struct PostContextMenu: View {
  // MARK: Internal

  let post: Post
  @Binding var presentReplyForm: Bool

  var body: some View {
    Button(action: {
      showComments(for: post)
    }, label: {
      Text("Show comments…")
    })
    Button(action: {
      withAnimation {
        presentReplyForm = true
      }
    }, label: {
      Text("Reply…")
    })
    Menu("Open in Browser…") {
      Button(action: {
        openLink(post.postUrl)
      }, label: {
        Text("Post…")
      })
      Button(action: {
        openLink(post.contentUrl)
      }, label: {
        Text("Post content…")
      })
    }
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
        Text(verbatim: "Show debug panel…")
      }
    #endif
  }

  // MARK: Private

  private let windowManager: WindowManager = .shared

  private func showComments(for post: Post) {
    windowManager.showMainWindowTab(withId: post.name, title: post.title) {
      CommentsView(post: post)
    }
  }

  private func showDebugWindow(for post: Post) {
    windowManager.showMainWindowTab(withId: "\(post.name)_debug", title: "\(post.title) - Debug View") {
      PostDebugView(post: post)
    }
  }
}

// struct PostContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        PostContextMenu()
//    }
// }
