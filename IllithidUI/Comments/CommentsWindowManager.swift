//
//  CommentsWindowManager.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/19/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Foundation
import SwiftUI

import Illithid

final class CommentsWindowManager {
  let reddit: RedditClientBroker

  init(reddit: RedditClientBroker) {
    self.reddit = reddit
  }

  static let styleMask: NSWindow.StyleMask = [
    .resizable,
    .titled,
    .closable
  ]
  fileprivate var controllers: [Post: WindowController<CommentsView>] = [:]

  func showWindow(for post: Post) {
    if let controller = windowController(for: post) {
      controller.window?.center()
      controller.window?.makeKeyAndOrderFront(nil)
    } else {
      let controller = makeWindowController(for: post)
      controller.window?.center()
      controller.window?.makeKeyAndOrderFront(nil)
    }
  }

  fileprivate func windowController(for post: Post) -> WindowController<CommentsView>? {
    return controllers[post]
  }

  fileprivate func makeWindowController(for post: Post) -> WindowController<CommentsView> {
    let controller = WindowController(rootView: CommentsView(commentData: .init(), post: post, reddit: reddit), styleMask: Self.styleMask, title: post.title)
    controllers[post] = controller
    return controller
  }
}
