//
// WindowManager.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class WindowManager {
  static let shared = WindowManager()
  
  typealias ID = String

  private let styleMask: NSWindow.StyleMask = [
    .resizable,
    .titled,
    .closable,
  ]

  private var controllers: [String: (controller: WindowController, token: AnyCancellable)] = [:]

  @discardableResult
  func showWindow<Content: View>(withId id: ID,
                                 title: String = "Reddit: The only newspaper that flays your mind",
                                 @ViewBuilder view: () -> Content) -> WindowController {
    if let controller = windowController(withId: id) {
      if !(NSApp.mainWindow?.tabGroup?.windows.contains(controller.window!) ?? true) {
        NSApp.mainWindow?.addTabbedWindow(controller.window!, ordered: .above)
      }
      controller.window!.makeKeyAndOrderFront(nil)
      return controller
    } else {
      let controller = makeWindowController(with: id, title: title, view: view)
      NSApp.mainWindow?.addTabbedWindow(controller.window!, ordered: .above)
      controller.window!.makeKeyAndOrderFront(nil)
      return controller
    }
  }

  func newRootWindow() {
    WindowManager.shared.showWindow(withId: UUID().uuidString,
                                    title: "Reddit: The only newspaper that flays your mind") {
                                      RootView()
    }
  }

  fileprivate func windowController(withId id: ID) -> WindowController? {
    controllers[id]?.controller
  }

  fileprivate func makeWindowController<Content: View>(with id: ID, title: String = "",
                                                       @ViewBuilder view: () -> Content) -> WindowController {
    let controller = WindowController()
    controller.window = Window(styleMask: styleMask, title: title, rootView: view)
    controller.window!.tabbingIdentifier = id
    controller.window!.tab.title = title
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
            self.showWindow(withId: multi.id, title: multi.displayName) {
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
          self.showWindow(withId: subreddit.id, title: subreddit.displayName) {
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
          self.showWindow(withId: account.id, title: account.name) {
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
          self.showWindow(withId: post.fullname, title: post.title) {
             CommentsView(post: post, focusOn: focusedCommentId)
           }
         case let .failure(error):
           Illithid.shared.logger.errorMessage("Unable to fetch post: \(error)")
         }
       }
     }
   }
}
