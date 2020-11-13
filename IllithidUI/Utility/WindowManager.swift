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

import Combine
import Foundation
import SwiftUI

import Illithid

final class WindowManager {
  // MARK: Internal

  typealias ID = String

  static let shared = WindowManager()
  static let defaultTitle = "Reddit: The only newspaper that flays your mind"

  static let defaultStyleMask: NSWindow.StyleMask = [
    .resizable,
    .titled,
    .closable,
  ]

  @discardableResult
  func showMainWindowTab<Content: View>(withId id: ID = UUID().uuidString,
                                        title: String = WindowManager.defaultTitle,
                                        @ViewBuilder view: () -> Content)
    -> WindowController {
    let controller = windowController(withId: id) ??
      makeWindowController(with: id, title: title, view: view)
    if !(NSApp.mainWindow?.tabGroup?.windows.contains(controller.window!) ?? true) {
      NSApp.mainWindow?.addTabbedWindow(controller.window!, ordered: .above)
    }
    controller.window!.makeKeyAndOrderFront(nil)
    return controller
  }

  @discardableResult
  func showWindow<Content: View>(withId id: ID = UUID().uuidString,
                                 title: String = WindowManager.defaultTitle,
                                 styleMask: NSWindow.StyleMask = WindowManager.defaultStyleMask,
                                 @ViewBuilder view: () -> Content)
    -> WindowController {
    let controller = windowController(withId: id) ??
      makeWindowController(with: id, title: title, styleMask: styleMask, view: view)
    controller.window!.makeKeyAndOrderFront(nil)
    return controller
  }

  func newRootWindow() {
    WindowManager.shared.showMainWindowTab(withId: UUID().uuidString) {
      RootView()
    }
  }

  // TODO: Move this elsewhere, likely into a factory class
  func openRedditLink(link: URL) {
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
          self.showMainWindowTab(withId: multi.id, title: multi.displayName) {
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
          self.showMainWindowTab(withId: subreddit.id, title: subreddit.displayName) {
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
          self.showMainWindowTab(withId: account.id, title: account.name) {
            AccountView(account: account)
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
          self.showMainWindowTab(withId: post.name, title: post.title) {
            CommentsView(post: post, focusOn: focusedCommentId)
          }
        case let .failure(error):
          Illithid.shared.logger.errorMessage("Unable to fetch post: \(error)")
        }
      }
    }
  }

  // MARK: Private

  private var controllers: [ID: (controller: WindowController, token: AnyCancellable)] = [:]

  private func windowController(withId id: ID) -> WindowController? {
    controllers[id]?.controller
  }

  private func makeWindowController<Content: View>(with id: ID, title: String = "",
                                                   styleMask: NSWindow.StyleMask = WindowManager.defaultStyleMask,
                                                   @ViewBuilder view: () -> Content)
    -> WindowController {
    let controller = WindowController()

    controller.window = NSWindow()
    controller.window!.title = title
    controller.window!.styleMask = styleMask
    controller.window!.tabbingIdentifier = id
    controller.window!.tab.title = title
    controller.window!.contentViewController = NSHostingController(rootView: view().environment(\.hostingWindow, .init(controller.window!)))

    let token = NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: controller.window)
      .compactMap { $0.object as? NSWindow }
      .sink { window in
        self.controllers.forEach { id, tuple in
          if window == tuple.controller.window {
            self.controllers.removeValue(forKey: id)
            tuple.token.cancel()
          }
        }
      }
    controllers[id] = (controller: controller, token: token)
    return controller
  }
}
