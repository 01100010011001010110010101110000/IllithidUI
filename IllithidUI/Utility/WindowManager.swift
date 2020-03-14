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
  func showWindow<Content: View>(withId id: ID, title: String = "", @ViewBuilder view: () -> Content) -> WindowController {
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
}
