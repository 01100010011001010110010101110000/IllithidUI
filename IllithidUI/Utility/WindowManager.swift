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

final class WindowManager<V: IdentifiableView> {
  let styleMask: NSWindow.StyleMask = [
    .resizable,
    .titled,
    .closable
  ]
  fileprivate var controllers: [V.ID: WindowController<V>] = [:]

  func showWindow(for view: V, title: String = "") {
    if let controller = windowController(for: view) {
      controller.window?.center()
      controller.window?.makeKeyAndOrderFront(nil)
    } else {
      let controller = makeWindowController(for: view, title: title)
      controller.window?.center()
      controller.window?.makeKeyAndOrderFront(nil)
    }
  }

  fileprivate func windowController(for view: V) -> WindowController<V>? {
    return controllers[view.id]
  }

  fileprivate func makeWindowController(for view: V, title: String = "") -> WindowController<V> {
    let controller = WindowController(rootView: view, styleMask: self.styleMask, title: title)
    controllers[view.id] = controller
    return controller
  }
}

protocol IdentifiableView: View, Identifiable {}
