//
// WindowManager.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class WindowManager<V: View & Identifiable>: ObservableObject {
  let styleMask: NSWindow.StyleMask = [
    .resizable,
    .titled,
    .closable,
  ]
  fileprivate var controllers: [V.ID: WindowController<V>] = [:]
  fileprivate var cancelBag: [AnyCancellable] = []

  func showWindow(for view: V, title: String = "") {
    if let controller = windowController(for: view) {
      controller.window?.center()
      controller.window?.makeKeyAndOrderFront(nil)
    } else {
      let controller = makeWindowController(for: view, title: title)
      cancelBag.append(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: controller.window)
        .compactMap { $0.object as? NSWindow }
        .sink { window in
          self.controllers.forEach { id, controller in
            if window == controller.window { self.controllers.removeValue(forKey: id) }
          }
      })
      controller.window?.center()
      controller.window?.makeKeyAndOrderFront(nil)
    }
  }

  deinit {
    cancelBag.forEach { $0.cancel() }
  }

  fileprivate func windowController(for view: V) -> WindowController<V>? {
    controllers[view.id]
  }

  fileprivate func makeWindowController(for view: V, title: String = "") -> WindowController<V> {
    let controller = WindowController(rootView: view, styleMask: styleMask, title: title)
    controllers[view.id] = controller
    return controller
  }
}
