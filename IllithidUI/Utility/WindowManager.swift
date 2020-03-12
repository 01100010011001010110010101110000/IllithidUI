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

  private var controllers: [String: NSWindowController] = [:]
  private var cancelBag: [AnyCancellable] = []

  func showWindow<Content: View>(withId id: ID, title: String = "", @ViewBuilder view: () -> Content) {
    if let controller = windowController(withId: id) {
      if !(NSApp.mainWindow?.tabGroup?.windows.contains(controller.window!) ?? true) {
        NSApp.mainWindow?.addTabbedWindow(controller.window!, ordered: .above)
      }
      controller.window!.makeKeyAndOrderFront(nil)
    } else {
      let controller = makeWindowController(with: id, title: title, view: view)
      cancelBag.append(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: controller.window)
        .compactMap { $0.object as? NSWindow }
        .sink { window in
          self.controllers.forEach { id, controller in
            if window == controller.window { self.controllers.removeValue(forKey: id) }
          }
      })
      NSApp.mainWindow?.addTabbedWindow(controller.window!, ordered: .above)
      controller.window!.makeKeyAndOrderFront(nil)
    }
  }

  deinit {
    cancelBag.forEach { $0.cancel() }
  }

  fileprivate func windowController(withId id: ID) -> NSWindowController? {
    controllers[id]
  }

  fileprivate func makeWindowController<Content: View>(with id: ID, title: String = "",
                                                       @ViewBuilder view: () -> Content) -> NSWindowController {
    let controller = NSWindowController()
    controller.window = Window(styleMask: styleMask, title: title, rootView: view)
    controller.window!.tabbingIdentifier = id
    controller.window!.tab.title = title
    controllers[id] = controller
    return controller
  }
}
